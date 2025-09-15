# frozen_string_literal: true

module DiscourseLottery
  class LotterySerializer < ApplicationSerializer
    attributes :id, :name, :prize, :prize_image_url, :description, :draw_at, 
               :winner_count, :participant_threshold, :participant_count,
               :status, :fallback_strategy, :specified_winners, :created_at, :updated_at

    has_one :post, serializer: :basic_post, embed: :objects
    has_many :winners, serializer: :lottery_winner, embed: :objects
    has_many :participants, serializer: :lottery_participant, embed: :objects

    def participant_count
      object.participants.count
    end

    def include_winners?
      object.finished?
    end

    def include_participants?
      scope&.user&.staff? || (object.post&.user == scope&.user)
    end
  end

  class LotteryWinnerSerializer < ApplicationSerializer
    attributes :user_id, :username, :post_number, :rank, :created_at
    
    def username
      object.user.username
    end
  end

  class LotteryParticipantSerializer < ApplicationSerializer
    attributes :user_id, :username, :post_number, :created_at
    
    def username
      object.user.username
    end
  end
end
