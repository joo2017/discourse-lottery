# frozen_string_literal: true

DiscourseLottery::Engine.routes.draw do
  # 抽奖相关路由
  get "/discourse-lottery/lotteries" => "lotteries#index", :format => :json
  get "/discourse-lottery/lotteries/:id" => "lotteries#show"
  post "/discourse-lottery/lotteries" => "lotteries#create"
  delete "/discourse-lottery/lotteries/:id" => "lotteries#destroy"
  
  # 参与者相关路由
  post "/discourse-lottery/lotteries/:lottery_id/participants" => "participants#create"
  get "/discourse-lottery/lotteries/:lottery_id/participants" => "participants#index"
  delete "/discourse-lottery/lotteries/:lottery_id/participants/:id" => "participants#destroy"
end

Discourse::Application.routes.draw do
  mount ::DiscourseLottery::Engine, at: "/"
end
