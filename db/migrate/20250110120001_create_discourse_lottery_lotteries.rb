# frozen_string_literal: true

class CreateDiscourseLotteryLotteries < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_lotteries do |t|
      t.integer :post_id, null: false
      t.string :name, null: false, limit: 255
      t.text :prize, null: false
      t.string :prize_image_url, limit: 500
      t.datetime :draw_at, null: false
      t.integer :winner_count, null: false, default: 1
      t.string :specified_winners, limit: 1000
      t.integer :participant_threshold, null: false
      t.integer :fallback_strategy, null: false, default: 0
      t.text :description
      t.integer :status, null: false, default: 0
      # 移除数组字段，用独立表替代

      t.timestamps null: false
    end
  end
end
