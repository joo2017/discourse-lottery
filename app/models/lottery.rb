class Lottery < ActiveRecord::Base
  belongs_to :topic

  # 使用枚举提高代码可读性
  enum status: { running: 0, finished: 1, cancelled: 2 }
  enum fallback_strategy: { continue_draw: 0, cancel_activity: 1 }
  enum draw_type: { random: 0, specified: 1 }
end
