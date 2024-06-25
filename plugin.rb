# name: discourse-lottery
# about: Add lottery functionality to Discourse topics
# version: 0.1
# authors: Your Name
# url: https://github.com/yourusername/discourse-lottery

enabled_site_setting :lottery_enabled

register_asset "javascripts/discourse/templates/modal/create-lottery.hbs"
register_asset "javascripts/discourse/controllers/create-lottery.js.es6"

register_svg_icon "gift" if respond_to?(:register_svg_icon)

after_initialize do
  module ::DiscourseLottery
    class Engine < ::Rails::Engine
      engine_name "DiscourseLottery"
      isolate_namespace DiscourseLottery
    end
  end

  require_dependency "application_controller"
  class DiscourseLottery::LotteriesController < ::ApplicationController
    requires_plugin "DiscourseLottery"

    before_action :ensure_logged_in

    def create
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_edit!(topic)

      lottery = topic.create_lottery(lottery_params.merge(user: current_user))

      if lottery.save
        render json: lottery, serializer: BasicLotterySerializer
      else
        render json: { errors: lottery.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def draw
      lottery = ::DiscourseLottery::Lottery.find(params[:id])
      guardian.ensure_can_edit!(lottery.topic)

      winners = lottery.draw_winners

      render json: winners, each_serializer: BasicUserSerializer
    end

    private

    def lottery_params
      params.require(:lottery).permit(:prize_description, :winners_count, :end_condition, :end_value)
    end
  end

  class ::DiscourseLottery::Lottery < ::ActiveRecord::Base
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

  require_dependency 'topic'
  class ::Topic
    has_one :lottery, class_name: 'DiscourseLottery::Lottery'
  end

  add_to_serializer(:topic_view, :lottery) do
    BasicLotterySerializer.new(object.topic.lottery, root: false).as_json if object.topic.lottery
  end

  class ::DiscourseLottery::BasicLotterySerializer < ::ApplicationSerializer
    attributes :id, :prize_description, :winners_count, :end_condition, :end_value, :status
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
