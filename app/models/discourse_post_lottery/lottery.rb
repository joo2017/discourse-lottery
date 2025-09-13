# frozen_string_literal: true

module DiscoursePostLottery
  class Lottery < ActiveRecord::Base
    MIN_NAME_LENGTH = 5
    MAX_NAME_LENGTH = 255
    self.table_name = "discourse_post_lottery_lotteries"

    has_many :participants, foreign_key: :post_id, dependent: :delete_all
    has_many :winners, foreign_key: :post_id, dependent: :delete_all
    belongs_to :post, foreign_key: :id

    scope :visible, -> { where(deleted_at: nil) }

    validates :draw_time, presence: true
    validates :prize_name,
              length: {
                in: MIN_NAME_LENGTH..MAX_NAME_LENGTH,
              },
              unless: ->(lottery) { lottery.prize_name.blank? }

    def self.statuses
      @statuses ||= Enum.new(running: 0, finished: 1, cancelled: 2)
    end

    def running?
      status == Lottery.statuses[:running]
    end

    def finished?
      status == Lottery.statuses[:finished]
    end

    def cancelled?
      status == Lottery.statuses[:cancelled]
    end

    def expired?
      draw_time <= Time.now
    end

    def can_user_participate(user)
      return false if !running? || expired?
      return false if participants.exists?(user_id: user.id)
      true
    end

    def total_participants
      participants.count
    end

    def most_likely_participants(limit = 10)
      participants.order(:created_at).limit(limit)
    end

    def current_user_participated(user)
      return false unless user
      participants.exists?(user_id: user.id)
    end

    def can_act_on_discourse_post_lottery
      true # 前端展示用，实际权限在Guardian中控制
    end

    def sample_participants
      most_likely_participants
    end

    def creator
      post.user
    end
  end
end
