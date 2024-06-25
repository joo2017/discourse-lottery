class CreateLotteries < ActiveRecord::Migration[6.1]
  def change
    create_table :lotteries do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :prize_description
      t.integer :winners_count
      t.string :end_condition
      t.integer :end_value
      t.string :status, default: 'active'
      t.timestamps
    end
  end
end
