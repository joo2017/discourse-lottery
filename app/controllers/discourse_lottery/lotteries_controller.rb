# frozen_string_literal: true

module DiscourseLottery
  class LotteriesController < ::ApplicationController
    def show
      lottery = Lottery.find_by(post_id: params[:id])
      raise Discourse::NotFound unless lottery
      guardian.ensure_can_see!(lottery.post)
      render json: { lottery: LotterySerializer.new(lottery, scope: guardian, root: false).as_json }
    end
  end
end
