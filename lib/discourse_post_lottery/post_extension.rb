# frozen_string_literal: true

module DiscoursePostLottery
  module PostExtension
    extend ActiveSupport::Concern

    def lottery
      @lottery ||= DiscoursePostLottery::Lottery.find_by(id: id)
    end

    def lottery=(lottery_instance)
      @lottery = lottery_instance
    end
  end
end
