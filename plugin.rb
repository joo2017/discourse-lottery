# name: discourse-lottery
# about: Add lottery functionality to Discourse topics
# version: 0.1
# authors: Your Name
# url: https://github.com/yourusername/discourse-lottery

enabled_site_setting :lottery_enabled

register_asset "javascripts/discourse/templates/modal/create-lottery.hbs"
register_asset "javascripts/discourse/controllers/create-lottery.js.es6"

after_initialize do
  # 后端逻辑（如果有的话）
end
