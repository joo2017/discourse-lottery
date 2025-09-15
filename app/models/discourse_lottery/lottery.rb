# frozen_string_literal: true

module DiscourseLottery
  class Lottery < ActiveRecord::Base
    self.table_name = "discourse_lottery_lotteries"

    belongs_to :post, class_name: "::Post"
    has_many :participants, class_name: "DiscourseLottery::Participant", dependent: :destroy
    has_many :winners, class_name: "DiscourseLottery::Winner", dependent: :destroy

    enum status: { running: 0, finished: 1, cancelled: 2 }
    enum fallback_strategy: { continue: 0, cancel: 1 }

    validates :name, presence: true, length: { maximum: 255 }
    validates :prize, presence: true, length: { maximum: 1000 }
    validates :draw_at, presence: true
    validates :winner_count, presence: true, numericality: { greater_than: 0 }
    validates :participant_threshold, presence: true, numericality: { greater_than: 0 }
    validates :status, presence: true
    validates :fallback_strategy, presence: true

    validate :draw_at_must_be_future, on: :create
    validate :winner_count_not_greater_than_threshold

    scope :active, -> { where(status: :running) }
    scope :due_for_draw, -> { where("draw_at <= ?", Time.current) }

    def eligible_participants
      topic = post.topic
      posts = topic.posts.where("post_number > 1 AND deleted_at IS NULL")
      
      if specified_winners.present?
        winner_numbers = specified_winners.split(",").map(&:strip).map(&:to_i)
        posts = posts.where(post_number: winner_numbers)
      end
      
      posts.includes(:user).where.not(users: { id: post.user_id })
    end

    def publish_update!
      MessageBus.publish("/lottery/#{post.topic_id}", {
        type: "status_change",
        lottery_id: id,
        status: status,
        winners: winners.includes(:user).map { |w| 
          { 
            username: w.user.username, 
            post_number: w.post_number,
            rank: w.rank
          } 
        }
      })
    end

    private

    def draw_at_must_be_future
      return unless draw_at.present?
      
      if draw_at <= Time.current
        errors.add(:draw_at, "must be in the future")
      end
    end

    def winner_count_not_greater_than_threshold
      return unless winner_count.present? && participant_threshold.present?
      
      if winner_count > participant_threshold
        errors.add(:winner_count, "cannot be greater than participant threshold")
      end
    end
  end
end
