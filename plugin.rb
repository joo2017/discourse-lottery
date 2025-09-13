# frozen_string_literal: true
# name: discourse-lottery
# about: A lottery plugin for Discourse based on discourse-calendar
# version: 1.0
# authors: Your Name
# url: https://github.com/your-repo/discourse-lottery

PLUGIN_NAME = "discourse-lottery"

enabled_site_setting :discourse_lottery_enabled

# 注册资源
register_asset "stylesheets/common/discourse-lottery.scss"

# 加载引擎 - 这行必须在after_initialize之前
load File.expand_path("lib/discourse_lottery/engine.rb", __dir__)

after_initialize do
  # 加载扩展模块
  require_relative "lib/discourse_lottery/user_extension" if File.exist?(File.expand_path("lib/discourse_lottery/user_extension.rb", __dir__))
  
  # 扩展User模型
  User.class_eval do
    include DiscourseLottery::UserExtension if defined?(DiscourseLottery::UserExtension)
  end
  
  # 添加序列化器字段
  add_to_serializer(:current_user, :can_create_discourse_lottery) do
    object.respond_to?(:can_create_discourse_lottery?) ? object.can_create_discourse_lottery? : false
  end
end
