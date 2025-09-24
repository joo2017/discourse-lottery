# name: discourse-lottery
# about: A Discourse plugin to create and manage lotteries.
# version: 0.3.0
# authors: Your Name
# url: https://github.com/your-repo

enabled_site_setting :lottery_enabled

# 数据库、模型等后端代码
after_initialize do
  # 确保文件只加载一次
  %w[
    ../app/models/lottery.rb
    ../app/services/lottery_creator.rb
    ../app/jobs/regular/lock_lottery_post.rb
    ../app/jobs/regular/execute_lottery_draw.rb
  ].each { |path| load File.expand_path(path, __FILE__) }

  # 为 Topic 模型添加关联和自定义字段
  Topic.class_eval do
    has_one :lottery, dependent: :destroy
    
    # 存储用户表单的原始数据
    %i[
      lottery_activity_name
      lottery_prize_description
      lottery_prize_image_url
      lottery_draw_time
      lottery_winner_count
      lottery_specified_floors
      lottery_min_participants
      lottery_fallback_strategy
      lottery_extra_info
    ].each { |field| register_custom_field_type(field, :string) }
  end

  # 事件监听：当一个新主题被创建时
  DiscourseEvent.on(:topic_created) do |topic, _opts, _user|
    # 检查是否为抽奖帖 (通过自定义字段判断)
    if topic.custom_fields["lottery_activity_name"].present?
      LotteryCreator.new(topic).create!
    end
  end

  # 事件监听：当帖子被编辑时 (用于处理后悔期内的修改)
  DiscourseEvent.on(:post_edited) do |post, _topic_changes, _new_record|
    topic = post.topic
    # 仅处理主楼层 (post_number == 1) 的编辑
    # 且该主题是一个尚未锁定的抽奖
    if post.is_first_post? && topic&.lottery && topic.lottery.running?
      # 检查是否仍在后悔期内 (通过比较创建时间和当前时间)
      lock_delay = SiteSetting.lottery_post_lock_delay_minutes.minutes
      if lock_delay > 0 && (topic.created_at + lock_delay) > Time.zone.now
        # 注意: 简化处理，实际生产中可能需要更复杂的逻辑来更新，这里仅作演示
        # 重新运行创建/更新逻辑
        Rails.logger.info "Lottery topic #{topic.id} edited within regret period. Re-evaluating..."
        LotteryCreator.new(topic).create! # 这会覆盖旧记录和任务
      end
    end
  end

  # 将全局门槛值暴露给前端
  # 前端可以通过 Site.current().get('lottery_min_participants_global') 获取
  Site.preloaded_store_fields << "lottery_min_participants_global"
  def Site.preloaded_store_fields_dataset
    {
      "lottery_min_participants_global": SiteSetting.lottery_min_participants_global
    }
  end

  # 添加自定义标签
  register_topic_custom_field_type('is_lottery', :boolean)
  add_to_class(:topic, :is_lottery) { self.custom_fields['is_lottery'] }
  add_to_serializer(:topic_list_item, :is_lottery) { object.is_lottery }
end
