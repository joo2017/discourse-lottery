class LotteryCreator
  def initialize(topic)
    @topic = topic
    @user = topic.user
    @custom_fields = topic.custom_fields
  end

  def create!
    # 如果之前有记录，先销毁，用于支持后悔期编辑后的更新
    @topic.lottery&.destroy

    # --- 第一道防线：检查总开关 ---
    unless SiteSetting.lottery_enabled?
      post_failure_feedback(I18n.t("lottery.feedback.disabled"))
      return
    end

    # --- 第二道防线：检查必填项 ---
    required_fields = %w[lottery_activity_name lottery_prize_description lottery_draw_time lottery_winner_count lottery_min_participants lottery_fallback_strategy]
    if required_fields.any? { |field| @custom_fields[field].blank? }
      post_failure_feedback(I18n.t("lottery.feedback.missing_fields"))
      return
    end

    # --- 第三道防线：验证参与门槛 ---
    min_participants = @custom_fields["lottery_min_participants"].to_i
    global_min = SiteSetting.lottery_min_participants_global
    if min_participants < global_min
      post_failure_feedback(I18n.t("lottery.feedback.min_participants_too_low", min: global_min))
      return
    end
    
    # --- 智能判断抽奖方式 ---
    winner_count = @custom_fields["lottery_winner_count"].to_i
    draw_type = :random
    specified_floors_raw = @custom_fields["lottery_specified_floors"]
    specified_floors_parsed = []

    if specified_floors_raw.present?
      draw_type = :specified
      specified_floors_parsed = specified_floors_raw.split(',').map(&:strip).map(&:to_i).reject(&:zero?).uniq.sort
      if specified_floors_parsed.any?
        winner_count = specified_floors_parsed.count # 覆盖获奖人数
      else
        post_failure_feedback(I18n.t("lottery.feedback.invalid_specified_floors"))
        return
      end
    end

    # --- 创建与调度 ---
    begin
      lottery = @topic.create_lottery!(
        draw_time: Time.zone.parse(@custom_fields["lottery_draw_time"]),
        winner_count: winner_count,
        min_participants: min_participants,
        fallback_strategy: @custom_fields["lottery_fallback_strategy"].to_i == 0 ? :continue_draw : :cancel_activity,
        draw_type: draw_type,
        specified_floors: specified_floors_parsed.join(','),
        status: :running
      )

      # 清理旧任务 (用于后悔期编辑)
      Jobs.cancel_scheduled_job(:execute_lottery_draw, topic_id: @topic.id)
      Jobs.cancel_scheduled_job(:lock_lottery_post, topic_id: @topic.id)

      # 注册新任务
      Jobs.enqueue_at(lottery.draw_time, :execute_lottery_draw, lottery_id: lottery.id)
      
      lock_delay = SiteSetting.lottery_post_lock_delay_minutes
      if lock_delay > 0
        Jobs.enqueue_in(lock_delay.minutes, :lock_lottery_post, topic_id: @topic.id)
      else
        # 如果后悔期为0，立即锁定
        @topic.first_post.update(locked: true)
      end

      # 自动打标签
      tag_name = "抽奖中" # 可配置为SiteSetting
      Tagging.add_tags(DiscourseTagging.guardian, @topic, [tag_name])
      @topic.custom_fields['is_lottery'] = true
      @topic.save_custom_fields

    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      post_failure_feedback(I18n.t("lottery.feedback.creation_error", error: e.message))
    end
  end

  private

  def post_failure_feedback(reason)
    # 使用系统用户发帖，告知创建失败
    PostCreator.create!(
      Discourse.system_user,
      topic_id: @topic.id,
      raw: I18n.t("lottery.feedback.template", reason: reason, username: @user.username)
    )
  end
end
