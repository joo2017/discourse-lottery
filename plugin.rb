# frozen_string_literal: true

# name: discourse-lottery
# about: Adds the ability to create lottery activities in topics
# version: 1.0
# author: Based on discourse-calendar
# url: https://github.com/discourse/discourse-lottery

enabled_site_setting :lottery_enabled

# 注册前端资源
register_asset "stylesheets/common/discourse-post-lottery.scss"
register_asset "stylesheets/common/discourse-post-lottery-preview.scss"
register_asset "stylesheets/mobile/discourse-post-lottery.scss", :mobile
register_asset "stylesheets/colors.scss", :color_definitions

register_svg_icon "gift"
register_svg_icon "trophy"
register_svg_icon "dice"
register_svg_icon "users"

module ::DiscoursePostLottery
  PLUGIN_NAME = "discourse-post-lottery"
  
  TOPIC_POST_LOTTERY_STARTS_AT = "TopicLotteryStartsAt"  
  TOPIC_POST_LOTTERY_ENDS_AT = "TopicLotteryEndsAt"
end

require_relative "lib/discourse_post_lottery/engine"

after_initialize do
  # 加载模型扩展
  require_relative "lib/discourse_post_lottery/post_extension"

  # 前端需要的扩展
  reloadable_patch do
    Post.prepend(DiscoursePostLottery::PostExtension)
  end

  # 用户权限
  add_to_class(:user, :can_create_discourse_post_lottery?) do
    return @can_create_discourse_post_lottery if defined?(@can_create_discourse_post_lottery)
    @can_create_discourse_post_lottery =
      begin
        return true if staff?
        allowed_groups = SiteSetting.lottery_allowed_on_groups.to_s.split("|").compact
        allowed_groups.present? &&
          (
            allowed_groups.include?(Group::AUTO_GROUPS[:everyone].to_s) ||
              groups.where(id: allowed_groups).exists?
          )
      rescue StandardError
        false
      end
  end

  add_to_class(:guardian, :can_create_discourse_post_lottery?) do
    user && user.can_create_discourse_post_lottery?
  end

  add_to_class(:guardian, :can_act_on_discourse_post_lottery?) do |lottery|
    user && user.staff? || (user && Guardian.new(user).can_edit_post?(lottery.post))
  end

  add_to_serializer(:current_user, :can_create_discourse_post_lottery) do
    object.can_create_discourse_post_lottery?
  end

  # 前端需要的序列化
  add_to_serializer(
    :post,
    :lottery,
    include_condition: -> do
      SiteSetting.lottery_enabled && !object.nil? && !object.deleted_at.present?
    end,
  ) { object.lottery ? DiscoursePostLottery::LotterySerializer.new(object.lottery, scope: scope, root: false) : nil }

  # Topic自定义字段（前端显示需要）
  add_preloaded_topic_list_custom_field DiscoursePostLottery::TOPIC_POST_LOTTERY_STARTS_AT

  add_to_class(:topic, :lottery_starts_at) do
    @lottery_starts_at ||= custom_fields[DiscoursePostLottery::TOPIC_POST_LOTTERY_STARTS_AT]
  end

  add_to_serializer(
    :topic_list_item,
    :lottery_starts_at,
    include_condition: -> do
      SiteSetting.lottery_enabled && object.lottery_starts_at
    end,
  ) { object.lottery_starts_at }

  # 注册自定义字段
  register_post_custom_field_type("discourse_post_lottery", :string)
end
