# frozen_string_literal: true
# name: discourse-lottery
# about: A lottery plugin for Discourse based on discourse-calendar
# version: 1.0
# authors: Your Name
# url: https://github.com/your-repo/discourse-lottery

PLUGIN_NAME = "discourse-lottery"

enabled_site_setting :discourse_lottery_enabled

# 注册资源路径
register_asset "stylesheets/common/discourse-lottery.scss"
register_asset "stylesheets/desktop/discourse-lottery.scss", :desktop
register_asset "stylesheets/mobile/discourse-lottery.scss", :mobile

# 加载引擎
load File.expand_path("lib/discourse_lottery/engine.rb", __dir__)

after_initialize do
  # 加载所有扩展模块
  require_relative "lib/discourse_lottery/user_extension"
  require_relative "lib/discourse_lottery/post_extension"
  
  # 扩展核心模型
  User.class_eval do
    include DiscourseLottery::UserExtension
  end
  
  Post.class_eval do
    prepend DiscourseLottery::PostExtension
  end
  
  # 添加序列化器字段
  add_to_serializer(:current_user, :can_create_discourse_lottery) do
    object.can_create_discourse_lottery?
  end
  
  # 注册路由
  Discourse::Application.routes.draw do
    mount ::DiscourseLottery::Engine, at: "/"
  end
end
