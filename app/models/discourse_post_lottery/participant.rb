# frozen_string_literal: true

module DiscoursePostLottery
  class Participant < ActiveRecord::Base
    self.table_name = "discourse_post_lottery_participants"

    belongs_to :lottery, foreign_key: :post_id
    belongs_to :user

    default_scope { joins(:user).includes(:user).where("users.id IS NOT NULL") }
  end
end
