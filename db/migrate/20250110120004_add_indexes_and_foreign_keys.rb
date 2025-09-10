# frozen_string_literal: true

class AddIndexesAndForeignKeys < ActiveRecord::Migration[7.0]
  def change
    # 主表索引
    add_index :discourse_lottery_lotteries, :post_id, unique: true
    add_index :discourse_lottery_lotteries, [:status, :draw_at]
    add_index :discourse_lottery_lotteries, :draw_at
    add_index :discourse_lottery_lotteries, :status

    # 外键约束
    add_foreign_key :discourse_lottery_lotteries, :posts, column: :post_id, on_delete: :cascade
    add_foreign_key :discourse_lottery_participants, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :discourse_lottery_participants, :posts, column: :post_id, on_delete: :cascade
    add_foreign_key :discourse_lottery_winners, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :discourse_lottery_winners, :posts, column: :post_id, on_delete: :cascade
  end
end
