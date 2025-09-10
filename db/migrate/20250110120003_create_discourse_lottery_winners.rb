# frozen_string_literal: true

class CreateDiscourseLotteryWinners < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_winners do |t|
      t.references :lottery, null: false, foreign_key: { to_table: :discourse_lottery_lotteries }
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.integer :post_number, null: false
      t.integer :rank, null: false, default: 1  # 第几名（如果有多个奖项）
      t.datetime :won_at, null: false

      t.timestamps null: false
    end

    add_index :discourse_lottery_winners, [:lottery_id, :rank], unique: true
    add_index :discourse_lottery_winners, :user_id
    add_index :discourse_lottery_winners, :post_id
    add_index :discourse_lottery_winners, :won_at
  end
end
