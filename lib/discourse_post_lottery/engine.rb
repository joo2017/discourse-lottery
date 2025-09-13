# frozen_string_literal: true

module DiscourseLottery
  PLUGIN_NAME = "discourse-lottery"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseLottery
  end
end
