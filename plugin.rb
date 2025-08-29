# frozen_string_literal: true
# name: discourse-lottery
# about: Advanced lottery system with real-time features
# version: 2.0.0
# authors: Your Name
# url: https://github.com/username/discourse-lottery
# required_version: 3.2.0
# transpile_js: true

enabled_site_setting :lottery_enabled

register_asset "stylesheets/lottery.scss"
register_svg_icon "dice"

after_initialize do
  require_dependency "admin_constraint"
  
  # Load plugin components
  require_relative "app/models/lottery_draw"
  require_relative "app/controllers/lottery_controller"
  require_relative "app/jobs/regular/automated_draw_job"
  
  # Route registration
  add_admin_route "lottery.admin.title", "lottery"
  
  Discourse::Application.routes.append do
    get "/admin/plugins/lottery" => "admin/lottery_admin#index", 
        constraints: StaffConstraint.new
    
    resources :lottery_draws, only: [:index, :show] do
      resources :entries, controller: 'lottery_entries', only: [:index, :create, :destroy]
    end
  end
end
