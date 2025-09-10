# app/models/discourse_lottery/lottery.rb
module DiscourseLottery
  class Lottery < ActiveRecord::Base
    self.table_name = "discourse_lottery_lotteries"

    belongs_to :post, class_name: "Post"
    has_many :participants, class_name: "DiscourseLottery::Participant", dependent: :destroy
    has_many :winners, class_name: "DiscourseLottery::Winner", dependent: :destroy
    has_many :participating_users, through: :participants, source: :user
    has_many :winning_users, through: :winners, source: :user

    enum :status, { running: 0, finished: 1, cancelled: 2 }
    enum :fallback_strategy, { continue: 0, cancel: 1 }

    validates :name, :prize, :draw_at, :winner_count, :participant_threshold, presence: true
    validate :draw_at_must_be_in_the_future, on: :create

    def participant_count
      participants.count
    end

    def has_enough_participants?
      participant_count >= participant_threshold
    end

    def user_participating?(user)
      participants.exists?(user: user)
    end
  end
end

# app/models/discourse_lottery/participant.rb
module DiscourseLottery
  class Participant < ActiveRecord::Base
    self.table_name = "discourse_lottery_participants"

    belongs_to :lottery, class_name: "DiscourseLottery::Lottery"
    belongs_to :user, class_name: "User"
    belongs_to :post, class_name: "Post"

    validates :lottery, :user, :post, :post_number, :participated_at, presence: true
    validates :user_id, uniqueness: { scope: :lottery_id }
  end
end

# app/models/discourse_lottery/winner.rb
module DiscourseLottery
  class Winner < ActiveRecord::Base
    self.table_name = "discourse_lottery_winners"

    belongs_to :lottery, class_name: "DiscourseLottery::Lottery"
    belongs_to :user, class_name: "User"
    belongs_to :post, class_name: "Post"

    validates :lottery, :user, :post, :post_number, :rank, :won_at, presence: true
    validates :rank, uniqueness: { scope: :lottery_id }
  end
end
