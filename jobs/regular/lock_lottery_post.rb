# frozen_string_literal: true

module Jobs
  class LockLotteryPost < ::Jobs::Base
    def execute(args)
      post_id = args[:post_id]
      raise Discourse::InvalidParameters.new(:post_id) unless post_id

      post = Post.find_by(id: post_id)
      return unless post&.lottery&.running?

      lock_delay = SiteSetting.lottery_post_lock_delay_minutes.minutes
      if post.created_at + lock_delay <= Time.zone.now
        post.update_columns(locked: true)
      end
    end
  end
end
