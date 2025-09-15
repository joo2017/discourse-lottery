# lib/discourse_lottery/lottery_manager.rb
module DiscourseLottery
  class LotteryManager
    def self.execute_draw(lottery_id)
      lottery = Lottery.find_by(post_id: lottery_id)
      return unless lottery&.running?

      new(lottery).execute
    end

    def initialize(lottery)
      @lottery = lottery
    end

    def execute
      eligible_posts = @lottery.eligible_participants
      participant_count = eligible_posts.size

      # 记录所有参与者
      record_participants(eligible_posts)

      if participant_count < @lottery.participant_threshold && @lottery.cancel?
        cancel_lottery(I18n.t("lottery.results.cancelled_not_enough_participants"))
        return
      end

      winners = draw_winners(eligible_posts)

      if winners.empty?
        cancel_lottery(I18n.t("lottery.results.cancelled_no_valid_winners"))
      else
        finish_lottery(winners)
      end
    end

    private

    def record_participants(eligible_posts)
      # 清空现有参与者记录
      @lottery.participants.delete_all
      
      # 记录所有有效参与者
      eligible_posts.each do |post|
        @lottery.participants.create!(
          user_id: post.user_id,
          post_number: post.post_number,
          created_at: post.created_at
        )
      end
    end

    def draw_winners(eligible_posts)
      if @lottery.specified_winners.present?
        draw_specified_winners(eligible_posts)
      else
        draw_random_winners(eligible_posts)
      end
    end

    def draw_random_winners(eligible_posts)
      eligible_posts.sample(@lottery.winner_count)
    end

    def draw_specified_winners(eligible_posts)
      winner_post_numbers = @lottery.specified_winners.split(",").map(&:strip).map(&:to_i)
      eligible_posts.select { |p| winner_post_numbers.include?(p.post_number) }
    end

    def finish_lottery(winner_posts)
      # 清空现有获奖者记录
      @lottery.winners.delete_all
      
      # 记录获奖者
      winner_posts.each do |post|
        @lottery.winners.create!(
          user_id: post.user_id,
          post_number: post.post_number
        )
      end

      @lottery.update!(status: :finished)

      # 清理主题自定义字段，因为抽奖已结束
      @lottery.post.topic.custom_fields.delete(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT)
      @lottery.post.topic.save_custom_fields

      update_tags(I18n.t("lottery.tags.finished"))
      announce_winners(winner_posts)
      send_winner_pms(winner_posts)
      @lottery.post.topic.update!(locked: true)
      @lottery.publish_update!
    end

    def cancel_lottery(reason)
      @lottery.update!(status: :cancelled)
      
      # 清理主题自定义字段
      @lottery.post.topic.custom_fields.delete(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT)
      @lottery.post.topic.save_custom_fields
      
      update_tags(I18n.t("lottery.tags.cancelled"))
      announce_cancellation(reason)
      @lottery.publish_update!
    end

    def update_tags(new_tag_name)
      topic = @lottery.post.topic
      running_tag_name = I18n.t("lottery.tags.running")
      Tag.find_or_create_by!(name: new_tag_name)
      new_tag = Tag.find_by_name(new_tag_name)
      tags_to_keep = topic.tags.filter { |tag| tag.name != running_tag_name }
      topic.tags = tags_to_keep + [new_tag]
      topic.save!
    end

    def announce_winners(winner_posts)
      winner_list = winner_posts
        .map { |post| "- @#{post.user.username} (##{post.post_number})" }
        .join("\n")
      raw_content = I18n.t("lottery.results.winner_announcement", winners: winner_list)
      PostCreator.create!(Discourse.system_user, topic_id: @lottery.post.topic_id, raw: raw_content)
    end

    def send_winner_pms(winner_posts)
      winner_posts.each do |post|
        PostCreator.create!(
          Discourse.system_user,
          archetype: Archetype.private_message,
          target_usernames: post.user.username,
          title: I18n.t("lottery.results.pm_winner_title", name: @lottery.name),
          raw: I18n.t(
            "lottery.results.pm_winner_body",
            name: @lottery.name,
            prize: @lottery.prize,
            url: @lottery.post.full_url,
          ),
        )
      end
    end

    def announce_cancellation(reason)
      raw_content = I18n.t("lottery.results.cancellation_announcement", reason: reason)
      PostCreator.create!(Discourse.system_user, topic_id: @lottery.post.topic_id, raw: raw_content)
    end
  end
end
