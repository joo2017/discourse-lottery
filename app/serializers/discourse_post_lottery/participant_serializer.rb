# frozen_string_literal: true

module DiscoursePostLottery
  class ParticipantSerializer < ApplicationSerializer
    attributes :id, :post_number, :user, :post_id

    def user
      BasicUserSerializer.new(object.user, embed: :objects, root: false)
    end
  end
end
