# frozen_string_literal: true

module DiscourseLottery
  module UserExtension
    def can_create_discourse_lottery?
      return false unless SiteSetting.discourse_lottery_enabled
      
      if SiteSetting.discourse_lottery_allowed_on_groups.present?
        allowed_groups = SiteSetting.discourse_lottery_allowed_on_groups.split("|")
        return self.groups.where(name: allowed_groups).exists?
      end
      
      true
    end
  end
end
