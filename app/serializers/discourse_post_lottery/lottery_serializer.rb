# frozen_string_literal: true

module DiscoursePostLottery
  class LotterySerializer < ApplicationSerializer
    attributes :id
    attributes :prize_name
    attributes :prize_image  
    attributes :description
    attributes :draw_time
    attributes :winner_count
    attributes :min_participants
    attributes :draw_type
    attributes :fixed_floors
    attributes :fallback_strategy
    attributes :timezone
    attributes :status
    attributes :expired
    attributes :running
    attributes :finished
    attributes :cancelled
    attributes :total_participants
    attributes :can_act_on_discourse_post_lottery
    attributes :can_participate
    attributes :current_user_participated
    attributes :post
    attributes :creator
    attributes :sample_participants
    attributes :winners

    def expired
      object.expired?
    end

    def running
      object.running?
    end

    def finished
      object.finished?
    end

    def cancelled
      object.cancelled?
    end

    def can_participate
      scope.current_user && object.can_user_participate(scope.current_user)
    end

    def current_user_participated
      scope.current_user && object.current_user_participated(scope.current_user)
    end

    def post
      {
        id: object.post.id,
        post_number: object.post.post_number,
        url: object.post.url,
        topic: {
          id: object.post.topic.id,
          title: object.post.topic.title,
        },
      }
    end

    def creator
      BasicUserSerializer.new(object.creator, embed: :objects, root: false)
    end

    def sample_participants
      ActiveModel::ArraySerializer.new(
        object.sample_participants,
        each_serializer: ParticipantSerializer
      )
    end

    def winners
      return [] unless object.finished?
      ActiveModel::ArraySerializer.new(
        object.winners,
        each_serializer: WinnerSerializer
      )
    end

    def include_winners?
      object.finished?
    end
  end
end
