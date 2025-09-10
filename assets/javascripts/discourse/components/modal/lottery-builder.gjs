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
import { cook } from "discourse/lib/text";

export default class LotteryBuilder extends Component {
  @service siteSettings;
  @service messageBus;
  @service store;
  @service currentUser;

  @tracked name = this.args.model?.lottery?.name || "";
  @tracked prize = this.args.model?.lottery?.prize || "";
  @tracked prizeImageUrl = this.args.model?.lottery?.prize_image_url || "";
  @tracked drawAt = this.initDrawAt();
  @tracked winnerCount = this.args.model?.lottery?.winner_count || 1;
  @tracked specifiedWinners = this.args.model?.lottery?.specified_winners || "";
  @tracked participantThreshold = this.initParticipantThreshold();
  @tracked fallbackStrategy = this.args.model?.lottery?.fallback_strategy || "continue";
  @tracked description = this.args.model?.lottery?.description || "";
  @tracked uploading = false;
  @tracked saving = false;
  @tracked validationErrors = {};

  get isEditMode() {
    return this.args.model?.editMode && this.args.model?.lottery;
  }

  get modalTitle() {
    return this.isEditMode
      ? i18n("lottery.builder.edit_title")
      : i18n("lottery.builder.title");
  }

  get submitButtonLabel() {
    return this.isEditMode
      ? "lottery.builder.update_button"
      : "lottery.builder.create_button";
  }

  initDrawAt() {
    if (this.args.model?.lottery?.draw_at) {
      return moment(this.args.model.lottery.draw_at).format(
        "YYYY-MM-DDTHH:mm"
      );
    }
    return moment().add(1, "day").format("YYYY-MM-DDTHH:mm");
  }

  initParticipantThreshold() {
    return (
      this.args.model?.lottery?.participant_threshold ||
      this.siteSettings.lottery_min_participants_global ||
      5
    );
  }

  get isThresholdInvalid() {
    const threshold = parseInt(this.participantThreshold, 10);
    const globalMin = this.siteSettings.lottery_min_participants_global || 1;
    return threshold < globalMin;
  }

  get thresholdErrorMessage() {
    const globalMin = this.siteSettings.lottery_min_participants_global || 1;
    return i18n("lottery.builder.threshold_error", { count: globalMin });
  }

  get isSubmitDisabled() {
    return (
      this.isThresholdInvalid ||
      !this.name.trim() ||
      !this.prize.trim() ||
      !this.drawAt ||
      parseInt(this.winnerCount, 10) < 1 ||
      this.uploading ||
      this.saving ||
      this.hasValidationErrors
    );
  }

  get hasValidationErrors() {
    return Object.keys(this.validationErrors).length > 0;
  }

  get fallbackOptions() {
    return [
      { id: "continue", name: i18n("lottery.fallback_strategy.continue") },
      { id: "cancel", name: i18n("lottery.fallback_strategy.cancel") },
    ];
  }

  get drawTimeInPast() {
    if (!this.drawAt) return false;
    return moment(this.drawAt).isBefore(moment());
  }

  get canEditDrawTime() {
    return !this.isEditMode;
  }

  get canEditThreshold() {
    return !this.isEditMode;
  }

  get canEditFallbackStrategy() {
    return !this.isEditMode;
  }

  @action
  validateField(fieldName, value) {
    const errors = { ...this.validationErrors };

    switch (fieldName) {
      case "name":
        if (!value.trim()) {
          errors.name = "活动名称不能为空";
        } else {
          delete errors.name;
        }
        break;

      case "prize":
        if (!value.trim()) {
          errors.prize = "奖品描述不能为空";
        } else {
          delete errors.prize;
        }
        break;

      case "drawAt":
        if (!value) {
          errors.drawAt = "开奖时间不能为空";
        } else if (moment(value).isBefore(moment())) {
          errors.drawAt = "开奖时间不能早于当前时间";
        } else {
          delete errors.drawAt;
        }
        break;

      case "winnerCount":
        const count = parseInt(value, 10);
        if (isNaN(count) || count < 1) {
          errors.winnerCount = "获奖人数必须大于0";
        } else {
          delete errors.winnerCount;
        }
        break;

      case "participantThreshold":
        const threshold = parseInt(value, 10);
        const globalMin = this.siteSettings.lottery_min_participants_global || 1;
        if (isNaN(threshold) || threshold < globalMin) {
          errors.participantThreshold = `参与门槛不能少于${globalMin}人`;
        } else {
          delete errors.participantThreshold;
        }
        break;
    }

    this.validationErrors = errors;
  }

  @action
  onNameChange(event) {
    this.name = event.target.value;
    this.validateField("name", this.name);
  }

  @action
  onPrizeChange(event) {
    this.prize = event.target.value;
    this.validateField("prize", this.prize);
  }

  @action
  onPrizeImageUrlChange(event) {
    this.prizeImageUrl = event.target.value;
  }

  @action
  onDescriptionChange(event) {
    this.description = event.target.value;
  }

  @action
  onDrawAtChange(event) {
    this.drawAt = event.target.value;
    this.validateField("drawAt", this.drawAt);
  }

  @action
  onWinnerCountChange(event) {
    this.winnerCount = event.target.value;
    this.validateField("winnerCount", this.winnerCount);
  }

  @action
  onSpecifiedWinnersChange(event) {
    this.specifiedWinners = event.target.value;
  }

  @action
  onParticipantThresholdChange(event) {
    this.participantThreshold = event.target.value;
    this.validateField("participantThreshold", this.participantThreshold);
  }

  @action
  onFallbackStrategyChange(value) {
    this.fallbackStrategy = value;
  }

  @action
  onFileChange(event) {
    const file = event.target.files[0];
    if (!file) return;

    // 验证文件类型
    const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];
    if (!allowedTypes.includes(file.type)) {
      alert(i18n("upload.unauthorized_type_extension"));
      return;
    }

    // 验证文件大小 (10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      alert(i18n("upload.file_too_big"));
      return;
    }

    this.uploading = true;
    this.uploadFile(file);
  }

  async uploadFile(file) {
    try {
      const formData = new FormData();
      formData.append("files[]", file);
      formData.append("upload_type", "composer");
      formData.append("client_id", this.messageBus.clientId);

      const response = await ajax("/uploads.json", {
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
      });

      if (response && response.url) {
        this.prizeImageUrl = response.url;
      } else if (response && response.short_url) {
        const baseUrl = window.location.origin;
        this.prizeImageUrl = response.short_url.startsWith("upload://")
          ? `${baseUrl}/uploads/default/original/1X/` +
            response.short_url.replace("upload://", "") +
            ".webp"
          : response.short_url;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.uploading = false;
    }
  }

  @action
  async createOrUpdateLottery() {
    if (this.isSubmitDisabled) {
      return;
    }

    // 最终验证
    this.validateField("name", this.name);
    this.validateField("prize", this.prize);
    this.validateField("drawAt", this.drawAt);
    this.validateField("winnerCount", this.winnerCount);
    this.validateField("participantThreshold", this.participantThreshold);

    if (this.hasValidationErrors) {
      return;
    }

    this.saving = true;

    try {
      if (this.isEditMode) {
        await this.updateExistingLottery();
      } else {
        await this.createNewLottery();
      }

      this.args.closeModal();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  async createNewLottery() {
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
    if (this.specifiedWinners.trim()) {
      attrs.specifiedWinners = `"${this.specifiedWinners}"`;
    }
    if (this.description.trim()) {
      attrs.description = `"${this.description}"`;
    }

    const bbcode = `[lottery ${Object.entries(attrs)
      .map(([k, v]) => `${k}=${v}`)
      .join(" ")}]\n[/lottery]`;

    if (this.args.model.toolbarEvent) {
      this.args.model.toolbarEvent.addText(bbcode);
    }
  }

  async updateExistingLottery() {
    const lottery = this.args.model.lottery;
    const post = await this.store.find("post", lottery.post.id);

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
    if (this.specifiedWinners.trim()) {
      attrs.specifiedWinners = `"${this.specifiedWinners}"`;
    }
    if (this.description.trim()) {
      attrs.description = `"${this.description}"`;
    }

    const newBbcode = `[lottery ${Object.entries(attrs)
      .map(([k, v]) => `${k}=${v}`)
      .join(" ")}]\n[/lottery]`;

    // 替换现有的抽奖BBCode
    const lotteryRegex = /\[lottery\s+.*?\]\s*\[\/lottery\]/ms;
    const newRaw = post.raw.replace(lotteryRegex, newBbcode);

    const props = {
      raw: newRaw,
      edit_reason: i18n("lottery.edit_reason.updated"),
    };

    const cooked = await cook(newRaw);
    props.cooked = cooked.string;

    await post.save(props);
  }

  <template>
    <DModal
      @title={{this.modalTitle}}
      @closeModal={{@closeModal}}
      class="lottery-builder-modal"
    >
      <:body>
        <form class="lottery-builder-form">
          <div class="lottery-field">
            <label for="lottery-name">{{i18n "lottery.builder.name_label"}}</label>
            <Input
              @value={{this.name}}
              @input={{this.onNameChange}}
              id="lottery-name"
              class="d-input {{if this.validationErrors.name 'error'}}"
              placeholder="请输入活动名称"
            />
            {{#if this.validationErrors.name}}
              <div class="validation-error">{{this.validationErrors.name}}</div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-prize">{{i18n "lottery.builder.prize_label"}}</label>
            <Input
              @value={{this.prize}}
              @input={{this.onPrizeChange}}
              id="lottery-prize"
              class="d-input {{if this.validationErrors.prize 'error'}}"
              placeholder="请输入奖品描述"
            />
            {{#if this.validationErrors.prize}}
              <div class="validation-error">{{this.validationErrors.prize}}</div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-prize-image">{{i18n "lottery.builder.prize_image_label"}}</label>
            <p class="description">{{i18n "lottery.builder.prize_image_url_desc"}}</p>
            <Input
              @value={{this.prizeImageUrl}}
              @input={{this.onPrizeImageUrlChange}}
              id="lottery-prize-image"
              placeholder="https://example.com/image.jpg"
              class="d-input"
            />
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
                <img
                  src={{this.prizeImageUrl}}
                  alt="Prize preview"
                  style="max-width: 200px; margin-top: 10px;"
                />
              </div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-draw-at">{{i18n "lottery.builder.draw_at_label"}}</label>
            <input
              type="datetime-local"
              value={{this.drawAt}}
              {{on "change" this.onDrawAtChange}}
              id="lottery-draw-at"
              required
              class="d-input {{if this.validationErrors.drawAt 'error'}}"
              disabled={{this.isEditMode}}
            />
            {{#if this.isEditMode}}
              <p class="description notice">{{i18n "lottery.builder.draw_at_locked_notice"}}</p>
            {{/if}}
            {{#if this.validationErrors.drawAt}}
              <div class="validation-error">{{this.validationErrors.drawAt}}</div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-winner-count">{{i18n "lottery.builder.winner_count_label"}}</label>
            <p class="description">{{i18n "lottery.builder.winner_count_desc"}}</p>
            <Input
              @type="number"
              @value={{this.winnerCount}}
              @input={{this.onWinnerCountChange}}
              id="lottery-winner-count"
              min="1"
              class="d-input {{if this.validationErrors.winnerCount 'error'}}"
            />
            {{#if this.validationErrors.winnerCount}}
              <div class="validation-error">{{this.validationErrors.winnerCount}}</div>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-specified-winners">{{i18n "lottery.builder.specified_winners_label"}}</label>
            <p class="description">{{i18n "lottery.builder.specified_winners_desc"}}</p>
            <Input
              @value={{this.specifiedWinners}}
              @input={{this.onSpecifiedWinnersChange}}
              id="lottery-specified-winners"
              placeholder="8, 18, 28"
              class="d-input"
            />
          </div>

          <div class="lottery-field">
            <label for="lottery-threshold">{{i18n "lottery.builder.participant_threshold_label"}}</label>
            <Input
              @type="number"
              @value={{this.participantThreshold}}
              @input={{this.onParticipantThresholdChange}}
              id="lottery-threshold"
              min={{this.siteSettings.lottery_min_participants_global}}
              class="d-input {{if this.validationErrors.participantThreshold 'error'}}"
              disabled={{this.isEditMode}}
            />
            {{#if this.isThresholdInvalid}}
              <div class="validation-error">{{this.thresholdErrorMessage}}</div>
            {{/if}}
            {{#if this.isEditMode}}
              <p class="description notice">{{i18n "lottery.builder.threshold_locked_notice"}}</p>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label>{{i18n "lottery.builder.fallback_strategy_label"}}</label>
            <ComboBox
              @content={{this.fallbackOptions}}
              @value={{this.fallbackStrategy}}
              @onChange={{this.onFallbackStrategyChange}}
              @disabled={{this.isEditMode}}
            />
            {{#if this.isEditMode}}
              <p class="description notice">{{i18n "lottery.builder.strategy_locked_notice"}}</p>
            {{/if}}
          </div>

          <div class="lottery-field">
            <label for="lottery-description">{{i18n "lottery.builder.description_label"}}</label>
            <Textarea
              @value={{this.description}}
              @input={{this.onDescriptionChange}}
              id="lottery-description"
              rows="4"
              class="d-input"
              placeholder="可选的补充说明..."
            />
          </div>
        </form>
      </:body>
      <:footer>
        <DButton
          @action={{this.createOrUpdateLottery}}
          @label={{this.submitButtonLabel}}
          class="btn-primary"
          @disabled={{this.isSubmitDisabled}}
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}
