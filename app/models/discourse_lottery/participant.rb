# frozen_string_literal: true

module DiscourseLottery
  class Participant < ActiveRecord::Base
    self.table_name = "discourse_lottery_participants"

    belongs_to :lottery, class_name: "DiscourseLottery::Lottery"
    belongs_to :user, class_name: "::User"

    validates :user_id, presence: true, uniqueness: { scope: :lottery_id }
    validates :post_number, presence: true
  end
end
