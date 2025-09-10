# app/serializers/discourse_lottery/lottery_serializer.rb
module DiscourseLottery
  class LotterySerializer < ApplicationSerializer
    attributes :id, :name, :prize, :prize_image_url, :draw_at, :winner_count, :participant_threshold,
               :fallback_strategy, :description, :status, :winners, :post, :participant_count

    def id
      object.post_id
    end

    def post
      {
        id: object.post.id,
        post_number: object.post.post_number,
        url: object.post.url,
        topic_id: object.post.topic_id
      }
    end

    def winners
      return [] unless object.finished?
      
      object.winners.includes(:user).map do |winner|
        {
          id: winner.user.id,
          username: winner.user.username,
          name: winner.user.name,
          avatar_template: winner.user.avatar_template,
          path: winner.user.path,
          post_number: winner.post_number
        }
      end
    end

    def participant_count
      object.participants.count
    end
  end
end
