# frozen_string_literal: true

module DiscourseLottery
  module PostLotteryExtension
    extend ActiveSupport::Concern

    prepended do
      has_one :lottery,
              class_name: "DiscourseLottery::Lottery",
              foreign_key: :post_id,
              dependent: :destroy
    end
  end
end
