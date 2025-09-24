class CreateLotteries < ActiveRecord::Migration[6.1]
  def change
    create_table :lotteries do |t|
      t.references :topic, null: false, foreign_key: true, index: { unique: true }
      t.datetime :draw_time, null: false
      t.integer :winner_count, null: false, default: 1
      t.integer :min_participants, null: false, default: 1
      t.integer :fallback_strategy, null: false, default: 0 # 0: continue, 1: cancel
      t.integer :draw_type, null: false, default: 0 # 0: random, 1: specified
      t.string :specified_floors
      t.integer :status, null: false, default: 0 # 0: running, 1: finished, 2: cancelled

      t.timestamps
    end
  end
end
