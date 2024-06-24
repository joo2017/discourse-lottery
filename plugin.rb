# plugin.rb
# name: discourse-lottery
# about: Add lottery functionality to Discourse topics
# version: 0.1
# authors: Your Name
# url: https://github.com/yourusername/discourse-lottery

enabled_site_setting :lottery_enabled

PLUGIN_NAME ||= "DiscourseLottery".freeze

after_initialize do
  module ::DiscourseLottery
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseLottery
    end
  end

  require_dependency "application_controller"
  class DiscourseLottery::LotteriesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def create
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_edit!(topic)

      lottery = topic.create_lottery(lottery_params.merge(user: current_user))

      if lottery.save
        render json: lottery, serializer: LotterySerializer
      else
        render_json_error(lottery)
      end
    end

    def draw
      lottery = Lottery.find(params[:id])
      guardian.ensure_can_edit!(lottery.topic)

      winners = lottery.draw_winners

      render json: winners, each_serializer: BasicUserSerializer
    end

    private

    def lottery_params
      params.require(:lottery).permit(:prize_description, :winners_count, :end_condition, :end_value)
    end
  end

  class ::Lottery < ::ActiveRecord::Base
    belongs_to :topic
    belongs_to :user

    validates :prize_description, presence: true
    validates :winners_count, presence: true, numericality: { greater_than: 0 }
    validates :end_condition, presence: true
    validates :end_value, presence: true

    def draw_winners
      participants = topic.posts.where("post_number > 1").map(&:user).uniq
      winners = participants.sample(winners_count)
      update(status: "completed")
      winners.each do |winner|
        notify_winner(winner)
      end
      winners
    end

    private

    def notify_winner(user)
      SystemMessage.create(user, :lottery_winner, 
        topic_title: topic.title,
        prize: prize_description
      )
    end
  end

  class ::Topic
    has_one :lottery
  end

  add_to_serializer(:topic_view, :lottery) do
    LotterySerializer.new(object.topic.lottery, root: false).as_json if object.topic.lottery
  end

  add_model_callback(Post, :after_create) do
    if self.is_first_post? && self.raw_parameters[:lottery]
      lottery_params = self.raw_parameters[:lottery]
      topic.create_lottery(lottery_params.merge(user: self.user))
    end
  end

  on(:post_created) do |post|
    if lottery = post.topic.lottery
      if lottery.end_condition == "post_count" && post.topic.posts.count >= lottery.end_value
        lottery.draw_winners
      end
    end
  end

  DiscourseLottery::Engine.routes.draw do
    post "/topics/:topic_id/lottery" => "lotteries#create"
    post "/lottery/:id/draw" => "lotteries#draw"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseLottery::Engine, at: "lottery"
  end
end
