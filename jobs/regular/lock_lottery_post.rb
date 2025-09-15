# frozen_string_literal: true

module Jobs
  class LockLotteryPost < ::Jobs::Base
    def execute(args)
      post_id = args[:post_id]
      return unless post_id

      post = Post.find_by(id: post_id)
      return unless post&.lottery

      post.update_columns(locked: true)
    end
  end
end
