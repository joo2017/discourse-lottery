# frozen_string_literal: true

class CreateDiscourseLotteryLotteries < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_lotteries do |t|
      t.references :post, null: false, foreign_key: true
      t.string :name, null: false
      t.text :prize, null: false
      t.string :prize_image_url
      t.text :description
      t.datetime :draw_at, null: false
      t.integer :winner_count, null: false, default: 1
      t.integer :participant_threshold, null: false, default: 5
      t.integer :status, null: false, default: 0
      t.integer :fallback_strategy, null: false, default: 0
      t.string :specified_winners
      t.timestamps
    end

    add_index :discourse_lottery_lotteries, :post_id, unique: true
    add_index :discourse_lottery_lotteries, :status
    add_index :discourse_lottery_lotteries, :draw_at
  end
end
