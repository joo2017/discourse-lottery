# frozen_string_literal: true

DiscourseLottery::Engine.routes.draw do
  get "/lotteries/:id" => "lotteries#show"
end

Discourse::Application.routes.draw do
  mount ::DiscourseLottery::Engine, at: "/"
end
