// assets/javascripts/discourse/components/admin-lottery-settings.gjs
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

export default class AdminLotterySettings extends Component {
  @service siteSettings;
  @tracked isLoading = false;
  @tracked validationErrors = {};

  @action
  async validateApiKey(value) {
    if (!value || value.length < 10) {
      this.validationErrors.apiKey = "API key must be at least 10 characters";
      return false;
    }
    
    try {
      const response = await ajax("/admin/lottery/validate-key", {
        type: "POST",
        data: { key: value }
      });
      
      if (!response.valid) {
        this.validationErrors.apiKey = response.error;
        return false;
      }
    } catch (error) {
      this.validationErrors.apiKey = "Validation failed";
      return false;
    }
    
    delete this.validationErrors.apiKey;
    return true;
  }

  @action
  async saveSetting(settingName, value) {
    this.isLoading = true;
    
    try {
      if (settingName === 'lottery_api_key') {
        const isValid = await this.validateApiKey(value);
        if (!isValid) return;
      }
      
      await this.siteSettings.update(settingName, value);
      this.dialog.notice(I18n.t("admin.saved"));
    } catch (error) {
      this.dialog.alert(error.message);
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <div class="admin-lottery-settings">
      <DToggleSwitch 
        @state={{this.siteSettings.lottery_enabled}}
        @label="lottery.admin.enable_lottery"
        {{on "change" (fn this.saveSetting "lottery_enabled")}}
      />
      
      <div class="setting-group">
        <label>{{i18n "lottery.admin.api_key_label"}}</label>
        <Input 
          @type="password"
          @value={{this.siteSettings.lottery_api_key}}
          {{on "blur" (fn this.validateApiKey this.siteSettings.lottery_api_key)}}
          class={{if this.validationErrors.apiKey "error"}}
        />
        
        {{#if this.validationErrors.apiKey}}
          <div class="validation-error">{{this.validationErrors.apiKey}}</div>
        {{/if}}
      </div>
    </div>
  </template>
}
