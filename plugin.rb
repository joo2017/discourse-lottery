# frozen_string_literal: true

# name: discourse-lottery
# about: A plugin to create and manage automated lotteries in Discourse topics.
# version: 1.0
# author: Your Name (based on discourse-lottery-v6 blueprint)
# url: https://github.com/your-repo/discourse-lottery

enabled_site_setting :lottery_enabled

register_asset "stylesheets/common/lottery.scss"
register_svg_icon "gift"

module ::DiscourseLottery
  PLUGIN_NAME = "discourse-lottery"
  TOPIC_LOTTERY_DRAW_AT = "lottery_draw_at"
end

require_relative "lib/discourse_lottery/engine"

after_initialize do
  # Libs & Services
  require_relative "lib/post_lottery_extension"
  require_relative "lib/discourse_lottery/lottery_creator"
  require_relative "lib/discourse_lottery/lottery_manager"
  require_relative "lib/discourse_lottery/lottery_validator"

  # Jobs
  require_relative "jobs/regular/execute_lottery_draw"
  require_relative "jobs/regular/lock_lottery_post"

  # Core extensions
  reloadable_patch do |plugin|
    Post.prepend(DiscourseLottery::PostLotteryExtension)
  end

  add_to_class(:post, :lottery) do
    @lottery ||= DiscourseLottery::Lottery.find_by(post_id: self.id)
  end

  # 注册自定义字段类型
  register_topic_custom_field_type(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT, :string)

  # 确保自定义字段被预加载到主题列表
  if Topic.respond_to?(:preloaded_custom_fields)
    Topic.preloaded_custom_fields << DiscourseLottery::TOPIC_LOTTERY_DRAW_AT
  end

  if TopicList.respond_to?(:preloaded_topic_custom_fields)
    TopicList.preloaded_topic_custom_fields << DiscourseLottery::TOPIC_LOTTERY_DRAW_AT
  end

  if Site.respond_to?(:preloaded_topic_custom_fields)
    Site.preloaded_topic_custom_fields << DiscourseLottery::TOPIC_LOTTERY_DRAW_AT
  end

  # Serialize the lottery data with the post
  add_to_serializer(:post, :lottery, include_condition: -> { SiteSetting.lottery_enabled && object.is_first_post? && object.lottery.present? && !object.deleted_at }) do
    DiscourseLottery::LotterySerializer.new(object.lottery, scope: scope, root: false)
  end

  # 添加到主题列表序列化器
  add_to_serializer(:topic_list_item, :lottery_draw_at, include_condition: -> { 
    object.custom_fields && object.custom_fields[DiscourseLottery::TOPIC_LOTTERY_DRAW_AT].present? 
  }) do
    object.custom_fields[DiscourseLottery::TOPIC_LOTTERY_DRAW_AT]
  end

  # 添加到主题视图序列化器
  add_to_serializer(:topic_view, :lottery_draw_at, include_condition: -> { 
    object.topic.custom_fields && object.topic.custom_fields[DiscourseLottery::TOPIC_LOTTERY_DRAW_AT].present? 
  }) do
    object.topic.custom_fields[DiscourseLottery::TOPIC_LOTTERY_DRAW_AT]
  end

  # Hooks for creating/editing lotteries
  on(:post_created) do |post|
    if SiteSetting.lottery_enabled && post.is_first_post?
      DiscourseLottery::LotteryCreator.create(post)
    end
  end

  on(:post_edited) do |post|
    # A locked post means the lottery "regret period" is over.
    if SiteSetting.lottery_enabled && post.is_first_post? && post.lottery && !post.locked?
      DiscourseLottery::LotteryCreator.create(post)
    end
  end

  on(:post_destroyed) do |post|
    if SiteSetting.lottery_enabled && post.lottery
      post.lottery.destroy!
      # 清理主题自定义字段
      post.topic.custom_fields.delete(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT)
      post.topic.save_custom_fields
      
      Jobs.cancel_scheduled_job(:execute_lottery_draw, lottery_id: post.id)
      Jobs.cancel_scheduled_job(:lock_lottery_post, post_id: post.id)
    end
  end
end
