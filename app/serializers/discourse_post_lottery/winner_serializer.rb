# frozen_string_literal: true

module DiscoursePostLottery
  class WinnerSerializer < ApplicationSerializer
    attributes :id, :post_number, :user, :post_id, :won_at

    def user
      BasicUserSerializer.new(object.user, embed: :objects, root: false)
    end
  end
end
