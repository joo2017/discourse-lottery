# frozen_string_literal: true

class CreateDiscourseLotteryParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_lottery_participants do |t|
      t.references :lottery, null: false, foreign_key: { to_table: :discourse_lottery_lotteries }
      t.references :user, null: false, foreign_key: true
      t.integer :post_number, null: false
      t.timestamps
    end

    add_index :discourse_lottery_participants, [:lottery_id, :user_id], unique: true
    add_index :discourse_lottery_participants, :user_id
  end
end
