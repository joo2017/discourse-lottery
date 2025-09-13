# frozen_string_literal: true

module DiscoursePostLottery
  class Engine < ::Rails::Engine
    engine_name "discourse_post_lottery"
    isolate_namespace DiscoursePostLottery
    config.autoload_paths << File.join(config.root, "lib")
  end
end
