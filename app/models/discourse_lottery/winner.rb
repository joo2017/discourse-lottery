# frozen_string_literal: true

module DiscourseLottery
  class Winner < ActiveRecord::Base
    self.table_name = "discourse_lottery_winners"

    belongs_to :lottery, class_name: "DiscourseLottery::Lottery"
    belongs_to :user, class_name: "::User"

    validates :user_id, presence: true, uniqueness: { scope: :lottery_id }
    validates :post_number, presence: true
    validates :rank, presence: true, numericality: { greater_than: 0 }

    scope :ordered, -> { order(:rank) }

    before_create :set_rank

    private

    def set_rank
      self.rank = lottery.winners.count + 1
    end
  end
end
