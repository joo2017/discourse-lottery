# frozen_string_literal: true

module DiscourseLottery
  class LotteryCreator
    def self.create(post)
      validator = LotteryValidator.new(post)
      return unless validator.validate_lottery

      lottery_attrs = validator.parsed_lottery_attrs

      # Smart decision: specified winners override winner_count
      if lottery_attrs[:specified_winners].present?
        winner_numbers = lottery_attrs[:specified_winners].split(",").map(&:strip)
        lottery_attrs[:winner_count] = winner_numbers.size
      end

      lottery = Lottery.find_or_initialize_by(post_id: post.id)
      lottery.assign_attributes(lottery_attrs)

      if lottery.save
        # Cancel previous jobs to handle edits
        Jobs.cancel_scheduled_job(:execute_lottery_draw, lottery_id: lottery.post_id)
        Jobs.cancel_scheduled_job(:lock_lottery_post, post_id: lottery.post_id)

        # Schedule new jobs
        Jobs.enqueue_at(lottery.draw_at, :execute_lottery_draw, lottery_id: lottery.post_id)

        lock_delay = SiteSetting.lottery_post_lock_delay_minutes
        if lock_delay > 0
          Jobs.enqueue_in(lock_delay.minutes, :lock_lottery_post, post_id: lottery.post_id)
        else
          post.update_columns(locked: true) # Lock immediately
        end

        # Ensure "抽奖中" tag is present
        tag_name = I18n.t("lottery.tags.running")
        Tag.find_or_create_by!(name: tag_name)
        topic = post.topic
        unless topic.tags.exists?(name: tag_name)
          topic.tags << Tag.find_by_name(tag_name)
          topic.save!
        end
      else
        notify_failure(post, lottery.errors.full_messages.join("\n"))
      end
    rescue => e
      notify_failure(post, e.message)
      Rails.logger.error("Lottery creation failed: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    def self.notify_failure(post, reason)
      PostCreator.create!(
        Discourse.system_user,
        topic_id: post.topic_id,
        raw: I18n.t("lottery.errors.creation_failed_feedback", reason: reason, user_mention: "@#{post.user.username}"),
      )
    end
  end
end
