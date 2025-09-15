# frozen_string_literal: true

# name: discourse-lottery
# about: A plugin to create and manage automated lotteries in Discourse topics.
# version: 1.0
# author: Your Name
# url: https://github.com/your-repo/discourse-lottery

enabled_site_setting :lottery_enabled

register_asset "stylesheets/common/lottery.scss"
register_svg_icon "gift"

# 注册国际化文件
register_locale "config/locales/client.zh_CN.yml", :zh_CN

module ::DiscourseLottery
  PLUGIN_NAME = "discourse-lottery"
  TOPIC_LOTTERY_DRAW_AT = "lottery_draw_at"
end

require_relative "lib/discourse_lottery/engine"

after_initialize do
  # 其他代码保持不变...
  require_relative "lib/post_lottery_extension"
  require_relative "lib/discourse_lottery/lottery_creator"
  require_relative "lib/discourse_lottery/lottery_manager"
  require_relative "lib/discourse_lottery/lottery_validator"

  require_relative "app/jobs/regular/execute_lottery_draw"
  require_relative "app/jobs/regular/lock_lottery_post"

  reloadable_patch do |plugin|
    Post.prepend(DiscourseLottery::PostLotteryExtension) if defined?(DiscourseLottery::PostLotteryExtension)
  end

  add_to_class(:post, :lottery) do
    @lottery ||= DiscourseLottery::Lottery.find_by(post_id: self.id)
  end

  register_topic_custom_field_type(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT, :string)

  TopicList.preloaded_custom_fields << DiscourseLottery::TOPIC_LOTTERY_DRAW_AT

  add_preloaded_topic_list_custom_field(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT)

  add_to_serializer(:post, :lottery, include_condition: -> { SiteSetting.lottery_enabled && object.is_first_post? && object.lottery.present? && !object.deleted_at }) do
    DiscourseLottery::LotterySerializer.new(object.lottery, scope: scope, root: false)
  end

  on(:post_created) do |post|
    if SiteSetting.lottery_enabled && post.is_first_post?
      DiscourseLottery::LotteryCreator.create(post)
    end
  end

  on(:post_edited) do |post|
    if SiteSetting.lottery_enabled && post.is_first_post? && post.lottery && !post.locked?
      DiscourseLottery::LotteryCreator.create(post)
    end
  end

  on(:post_destroyed) do |post|
    if SiteSetting.lottery_enabled && post.lottery
      post.lottery.destroy!
      post.topic.custom_fields.delete(DiscourseLottery::TOPIC_LOTTERY_DRAW_AT)
      post.topic.save_custom_fields
      
      Jobs.cancel_scheduled_job(:execute_lottery_draw, lottery_id: post.id)
      Jobs.cancel_scheduled_job(:lock_lottery_post, post_id: post.id)
    end
  end
end
