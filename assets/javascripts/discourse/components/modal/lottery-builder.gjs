import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { Input, Textarea } from "@ember/component";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import DModalCancel from "discourse/components/d-modal-cancel";
import ComboBox from "select-kit/components/combo-box";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import moment from "moment";
import { i18n } from "discourse-i18n";

export default class LotteryBuilder extends Component {
  @service siteSettings;
  @service messageBus;

  @tracked name = "";
  @tracked prize = "";
  @tracked prizeImageUrl = "";
  @tracked drawAt = moment().add(1, "day").format("YYYY-MM-DDTHH:mm");
  @tracked winnerCount = 1;
  @tracked specifiedWinners = "";
  @tracked participantThreshold = this.siteSettings.lottery_min_participants_global;
  @tracked fallbackStrategy = "continue";
  @tracked description = "";
  @tracked uploading = false;

  get isThresholdInvalid() {
    return (
      parseInt(this.participantThreshold, 10) < this.siteSettings.lottery_min_participants_global
    );
  }

  get isSubmitDisabled() {
    return (
      this.isThresholdInvalid ||
      !this.name ||
      !this.prize ||
      !this.drawAt ||
      parseInt(this.winnerCount, 10) < 1 ||
      this.uploading
    );
  }

  get fallbackOptions() {
    return [
      { id: "continue", name: i18n("lottery.fallback_strategy.continue") },
      { id: "cancel", name: i18n("lottery.fallback_strategy.cancel") },
    ];
  }

  @action
  onFileChange(event) {
    const file = event.target.files[0];
    if (!file) return;

    // 验证文件类型
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      alert(i18n('upload.unauthorized_type_extension'));
      return;
    }

    // 验证文件大小 (10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      alert(i18n('upload.file_too_big'));
      return;
    }

    this.uploading = true;
    this.uploadFile(file);
  }

  async uploadFile(file) {
    try {
      const formData = new FormData();
      formData.append('files[]', file);
      // 修复: 使用最新的参数名
      formData.append('upload_type', 'composer');
      formData.append('client_id', this.messageBus.clientId);

      const response = await ajax('/uploads.json', {
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
      });

      if (response && response.url) {
        // 使用完整的URL而不是short_url
        this.prizeImageUrl = response.url;
      } else if (response && response.short_url) {
        // 如果只有short_url，尝试构建完整URL
        const baseUrl = window.location.origin;
        this.prizeImageUrl = response.short_url.startsWith('upload://') 
          ? `${baseUrl}/uploads/default/original/1X/` + response.short_url.replace('upload://', '') + '.webp'
          : response.short_url;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.uploading = false;
    }
  }

  @action
  onDrawAtChange(event) {
    this.drawAt = event.target.value;
  }

  @action
  onFallbackStrategyChange(value) {
    this.fallbackStrategy = value;
  }

  @action
  createLottery() {
    if (this.isSubmitDisabled) {
      return;
    }

    const drawAtUtc = moment(this.drawAt).utc().format("YYYY-MM-DD HH:mm");

    const attrs = {
      name: `"${this.name}"`,
      prize: `"${this.prize}"`,
      drawAt: `"${drawAtUtc}"`,
      winnerCount: `"${this.winnerCount}"`,
      participantThreshold: `"${this.participantThreshold}"`,
      fallbackStrategy: `"${this.fallbackStrategy}"`,
    };

    if (this.prizeImageUrl) {
      attrs.prizeImageUrl = `"${this.prizeImageUrl}"`;
    }
    if (this.specifiedWinners) {
      attrs.specifiedWinners = `"${this.specifiedWinners}"`;
    }
    if (this.description) {
      attrs.description = `"${this.description}"`;
    }

    const bbcode = `[lottery ${Object.entries(attrs).map(([k, v]) => `${k}=${v}`).join(" ")}]\n[/lottery]`;

    this.args.model.toolbarEvent.addText(bbcode);
    this.args.closeModal();
  }

  <template>
    <DModal 
      @title={{i18n "lottery.builder.title"}} 
      @closeModal={{@closeModal}} 
      class="lottery-builder-modal"
    >
      <:body>
        <form>
          <div class="lottery-field">
            <label>{{i18n "lottery.builder.name_label"}}</label>
            <Input @value={{this.name}} class="d-input" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.prize_label"}}</label>
            <Input @value={{this.prize}} class="d-input" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.prize_image_label"}}</label>
            <p class="description">{{i18n "lottery.builder.prize_image_url_desc"}}</p>
            <Input @value={{this.prizeImageUrl}} placeholder="https://example.com/image.jpg" class="d-input" />
            <br />
            <span class="description">{{i18n "lottery.builder.or_upload_file"}}</span>
            <input
              type="file"
              accept="image/*"
              {{on "change" this.onFileChange}}
              class="d-input"
              disabled={{this.uploading}}
            />
            {{#if this.uploading}}
              <div class="upload-progress">{{i18n "upload.uploading"}}</div>
            {{/if}}
            {{#if this.prizeImageUrl}}
              <div class="upload-preview">
                <img src={{this.prizeImageUrl}} alt="Prize preview" style="max-width: 200px; margin-top: 10px;" />
              </div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.draw_at_label"}}</label>
            <input
              type="datetime-local"
              value={{this.drawAt}}
              {{on "change" this.onDrawAtChange}}
              required
              class="d-input"
            />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.winner_count_label"}}</label>
            <p class="description">{{i18n "lottery.builder.winner_count_desc"}}</p>
            <Input @type="number" @value={{this.winnerCount}} min="1" class="d-input" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.specified_winners_label"}}</label>
            <p class="description">{{i18n "lottery.builder.specified_winners_desc"}}</p>
            <Input @value={{this.specifiedWinners}} placeholder="8, 18, 28" class="d-input" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.participant_threshold_label"}}</label>
            <Input
              @type="number"
              @value={{this.participantThreshold}}
              min={{this.siteSettings.lottery_min_participants_global}}
              class="d-input"
            />
            {{#if this.isThresholdInvalid}}
              <div class="error">{{i18n "lottery.builder.threshold_error" count=this.siteSettings.lottery_min_participants_global}}</div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.fallback_strategy_label"}}</label>
            <ComboBox 
              @content={{this.fallbackOptions}} 
              @value={{this.fallbackStrategy}} 
              @onChange={{this.onFallbackStrategyChange}} 
            />
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.description_label"}}</label>
            <Textarea @value={{this.description}} rows="4" class="d-input" />
          </div>
        </form>
      </:body>
      <:footer>
        <DButton
          @action={{this.createLottery}}
          @label="lottery.builder.create_button"
          class="btn-primary"
          @disabled={{this.isSubmitDisabled}}
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}
