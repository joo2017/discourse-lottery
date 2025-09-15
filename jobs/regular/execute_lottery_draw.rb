# frozen_string_literal: true

module Jobs
  class ExecuteLotteryDraw < ::Jobs::Base
    def execute(args)
      lottery_id = args[:lottery_id]
      return unless lottery_id

      DiscourseLottery::LotteryManager.execute_draw(lottery_id)
    end
  end
end
