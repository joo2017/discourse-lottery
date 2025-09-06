# plugin.rb - 插件主文件
# frozen_string_literal: true

# name: discourse-lottery
# about: 为 Discourse 论坛提供精准、公平、智能的抽奖系统
# version: 4.0.0
# authors: YourName
# url: https://github.com/yourusername/discourse-lottery
# required_version: 3.1.0

enabled_site_setting :lottery_enabled

register_asset 'stylesheets/common/discourse-lottery.scss'
register_asset 'stylesheets/mobile/discourse-lottery.scss', :mobile
register_asset 'stylesheets/desktop/discourse-lottery.scss', :desktop

# 注册SVG图标
register_svg_icon "dice" if respond_to?(:register_svg_icon)
register_svg_icon "trophy" if respond_to?(:register_svg_icon)

# 全局设置定义
add_admin_route 'lottery.admin_title', 'plugins.lottery'

# 站点设置
%w[
  lottery_enabled
  lottery_min_participants_global
  lottery_post_lock_delay_minutes
  lottery_excluded_groups
  lottery_allowed_categories
].each do |setting|
  register_site_setting_type(setting, String) if setting.end_with?('_groups', '_categories')
end

# 自定义字段注册 - 为前端模拟数据做准备
register_post_custom_field_type('lottery_name', :string)
register_post_custom_field_type('lottery_prize_description', :string)
register_post_custom_field_type('lottery_prize_image_url', :string)
register_post_custom_field_type('lottery_draw_time', :datetime)
register_post_custom_field_type('lottery_winner_count', :integer)
register_post_custom_field_type('lottery_fixed_floors', :string)
register_post_custom_field_type('lottery_min_participants', :integer)
register_post_custom_field_type('lottery_backup_strategy', :string)
register_post_custom_field_type('lottery_additional_notes', :text)
register_post_custom_field_type('lottery_status', :string)
register_post_custom_field_type('lottery_draw_method', :string)

# 序列化器扩展 - 将抽奖数据暴露给前端
add_to_serializer(:post, :lottery_data) do
  return nil unless object.custom_fields['lottery_name']
  
  {
    id: object.id,
    name: object.custom_fields['lottery_name'],
    prize_description: object.custom_fields['lottery_prize_description'],
    prize_image_url: object.custom_fields['lottery_prize_image_url'],
    draw_time: object.custom_fields['lottery_draw_time'],
    winner_count: object.custom_fields['lottery_winner_count'],
    fixed_floors: object.custom_fields['lottery_fixed_floors'],
    min_participants: object.custom_fields['lottery_min_participants'],
    backup_strategy: object.custom_fields['lottery_backup_strategy'],
          additional_notes: object.custom_fields['lottery_additional_notes'],
      status: object.custom_fields['lottery_status'] || 'running',
      draw_method: object.custom_fields['lottery_draw_method'] || 'random',
      current_participants: 0,
      time_remaining: nil,
      winners: []
    }
  end

  add_to_serializer(:post, :include_lottery_data?) do
    object.custom_fields['lottery_name'].present?
  end

  # 将全局设置暴露给前端
  add_to_serializer(:site, :lottery_settings) do
    {
      enabled: SiteSetting.lottery_enabled,
      min_participants_global: SiteSetting.lottery_min_participants_global,
      post_lock_delay_minutes: SiteSetting.lottery_post_lock_delay_minutes,
      excluded_groups: SiteSetting.lottery_excluded_groups.split('|'),
      allowed_categories: SiteSetting.lottery_allowed_categories.split('|')
    }
  end

  # 事件监听器
  DiscourseEvent.on(:topic_created) do |topic|
    # 后续实现抽奖创建逻辑
  end
  
  DiscourseEvent.on(:post_edited) do |post|
    # 后续实现抽奖编辑逻辑
  end
end'],
    status: object.custom_fields['lottery_status'] || 'running',
    draw_method: object.custom_fields['lottery_draw_method'] || 'random',
    current_participants: 0, # 前端模拟数据
    time_remaining: nil,
    winners: []
  }
end

add_to_serializer(:post, :include_lottery_data?) do
  object.custom_fields['lottery_name'].present?
end

# 将全局设置暴露给前端
add_to_serializer(:site, :lottery_settings) do
  {
    enabled: SiteSetting.lottery_enabled,
    min_participants_global: SiteSetting.lottery_min_participants_global,
    post_lock_delay_minutes: SiteSetting.lottery_post_lock_delay_minutes,
    excluded_groups: SiteSetting.lottery_excluded_groups.split('|'),
    allowed_categories: SiteSetting.lottery_allowed_categories.split('|')
  }
end

# 初始化插件
after_initialize do
  # 这里后续会添加 Jobs、Services 等后端逻辑
  # 目前专注于前端实现
  
  # 简单的事件监听器 - 为前端测试提供数据
  DiscourseEvent.on(:topic_created) do |topic|
    # 后续实现抽奖创建逻辑
  end
  
  DiscourseEvent.on(:post_edited) do |post|
    # 后续实现抽奖编辑逻辑
  end
end
