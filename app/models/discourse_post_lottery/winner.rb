# frozen_string_literal: true

module DiscoursePostLottery  
  class Winner < ActiveRecord::Base
    self.table_name = "discourse_post_lottery_winners"

    belongs_to :lottery, foreign_key: :post_id
    belongs_to :user
  end
end
