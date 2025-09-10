# frozen_string_literal: true

class CreateDiscourseLotteryParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_participants do |t|
      t.references :lottery, null: false, foreign_key: { to_table: :discourse_lottery_lotteries }
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.integer :post_number, null: false
      t.datetime :participated_at, null: false

      t.timestamps null: false
    end

    add_index :discourse_lottery_participants, [:lottery_id, :user_id], unique: true
    add_index :discourse_lottery_participants, :user_id
    add_index :discourse_lottery_participants, :post_id
    add_index :discourse_lottery_participants, :participated_at
  end
end
