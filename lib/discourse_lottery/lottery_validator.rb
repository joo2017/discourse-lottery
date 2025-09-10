# frozen_string_literal: true

require "cgi"

module DiscourseLottery
  class LotteryValidator
    def initialize(post)
      @post = post
      @lottery_attrs = nil
    end

    def parsed_lottery_attrs
      @lottery_attrs
    end

    def validate_lottery
      raw_attrs = extract_lottery_attrs_from_raw
      return false unless raw_attrs.present?

      unless SiteSetting.lottery_enabled
        raise I18n.t("lottery.errors.plugin_disabled")
      end

      required_fields = %i[name prize draw_at winner_count participant_threshold fallback_strategy]
      required_fields.each do |field|
        if raw_attrs[field].blank?
          raise I18n.t("lottery.errors.missing_field", field: field.to_s)
        end
      end

      if raw_attrs[:participant_threshold].to_i < SiteSetting.lottery_min_participants_global
        raise I18n.t("lottery.errors.threshold_too_low", count: SiteSetting.lottery_min_participants_global)
      end

      # Type cast and finalize attributes
      @lottery_attrs = {
        name: raw_attrs[:name],
        prize: raw_attrs[:prize],
        prize_image_url: raw_attrs[:prize_image_url],
        draw_at: Time.zone.parse(raw_attrs[:draw_at]),
        winner_count: raw_attrs[:winner_count].to_i,
        specified_winners: raw_attrs[:specified_winners],
        participant_threshold: raw_attrs[:participant_threshold].to_i,
        fallback_strategy: raw_attrs[:fallback_strategy].to_sym,
        description: raw_attrs[:description]
      }

      true
    end

    private

    def extract_lottery_attrs_from_raw
      # Parse attributes from [lottery name="..." prize="..."]
      bbcode_match = @post.raw.match(/\[lottery\s+(.*?)\]/m)
      return nil unless bbcode_match

      attrs_string = bbcode_match[1]
      attrs = {}
      attrs_string.scan(/(\w+)=["'](.*?)["']/).each do |key, value|
        attrs[key.underscore.to_sym] = CGI.unescapeHTML(value)
      end
      attrs
    end
  end
end
