# frozen_string_literal: true

class CreateDiscourseLotteryWinners < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_winners do |t|
      t.references :lottery, null: false, foreign_key: { to_table: :discourse_lottery_lotteries }
      t.references :user, null: false, foreign_key: true
      t.integer :post_number, null: false
      t.integer :rank, null: false
      t.timestamps
    end

    add_index :discourse_lottery_winners, [:lottery_id, :user_id], unique: true
    add_index :discourse_lottery_winners, [:lottery_id, :rank], unique: true
    add_index :discourse_lottery_winners, :user_id
  end
end
