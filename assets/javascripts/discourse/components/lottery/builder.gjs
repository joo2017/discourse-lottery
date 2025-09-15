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
  @tracked showPreview = false;

  get isEditMode() {
    return this.args.model?.editMode && this.args.model?.lottery;
  }

  get modalTitle() {
    return this.isEditMode ? "编辑抽奖活动" : "创建抽奖活动";
  }

  get submitButtonLabel() {
    return this.isEditMode ? "更新抽奖" : "创建抽奖";
  }

  get previewData() {
    return {
      name: this.name || "抽奖活动",
      prize: this.prize || "奖品描述",
      prizeImageUrl: this.prizeImageUrl,
      drawAt: this.drawAt,
      winnerCount: this.winnerCount,
      participantThreshold: this.participantThreshold,
      fallbackStrategy: this.fallbackStrategy,
      description: this.description
    };
  }

  initDrawAt() {
    if (this.args.model?.lottery?.draw_at) {
      return moment(this.args.model.lottery.draw_at).format("YYYY-MM-DDTHH:mm");
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

  get isSubmitDisabled() {
    return (
      !this.name.trim() ||
      !this.prize.trim() ||
      !this.drawAt ||
      parseInt(this.winnerCount, 10) < 1 ||
      this.uploading ||
      this.saving
    );
  }

  get fallbackOptions() {
    return [
      { id: "continue", name: "继续开奖" },
      { id: "cancel", name: "取消抽奖" },
    ];
  }

  @action
  onNameChange(event) {
    this.name = event.target.value;
  }

  @action
  onPrizeChange(event) {
    this.prize = event.target.value;
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
  }

  @action
  onWinnerCountChange(event) {
    this.winnerCount = event.target.value;
  }

  @action
  onSpecifiedWinnersChange(event) {
    this.specifiedWinners = event.target.value;
  }

  @action
  onParticipantThresholdChange(event) {
    this.participantThreshold = event.target.value;
  }

  @action
  onFallbackStrategyChange(value) {
    this.fallbackStrategy = value;
  }

  @action
  togglePreview() {
    this.showPreview = !this.showPreview;
  }

  @action
  async createOrUpdateLottery() {
    if (this.isSubmitDisabled) {
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
    // 更新逻辑
  }

  <template>
    <DModal
      @title={{this.modalTitle}}
      @closeModal={{@closeModal}}
      class="lottery-builder-modal"
    >
      <:body>
        <div class="lottery-builder-container">
          <div class="lottery-builder-tabs">
            <button
              type="button"
              class="tab-button {{unless this.showPreview 'active'}}"
              {{on "click" (fn (mut this.showPreview) false)}}
            >
              表单设置
            </button>
            <button
              type="button"
              class="tab-button {{if this.showPreview 'active'}}"
              {{on "click" (fn (mut this.showPreview) true)}}
            >
              实时预览
            </button>
          </div>

          {{#unless this.showPreview}}
            <form class="lottery-builder-form">
              <div class="lottery-field">
                <label for="lottery-name">活动名称</label>
                <Input
                  @value={{this.name}}
                  @input={{this.onNameChange}}
                  id="lottery-name"
                  class="d-input"
                  placeholder="请输入活动名称"
                />
              </div>

              <div class="lottery-field">
                <label for="lottery-prize">奖品描述</label>
                <Input
                  @value={{this.prize}}
                  @input={{this.onPrizeChange}}
                  id="lottery-prize"
                  class="d-input"
                  placeholder="请输入奖品描述"
                />
              </div>

              <div class="lottery-field">
                <label for="lottery-draw-at">开奖时间</label>
                <input
                  type="datetime-local"
                  value={{this.drawAt}}
                  {{on "change" this.onDrawAtChange}}
                  id="lottery-draw-at"
                  required
                  class="d-input"
                />
              </div>

              <div class="lottery-field">
                <label for="lottery-winner-count">获奖人数</label>
                <Input
                  @type="number"
                  @value={{this.winnerCount}}
                  @input={{this.onWinnerCountChange}}
                  id="lottery-winner-count"
                  min="1"
                  class="d-input"
                />
              </div>

              <div class="lottery-field">
                <label for="lottery-threshold">参与门槛</label>
                <Input
                  @type="number"
                  @value={{this.participantThreshold}}
                  @input={{this.onParticipantThresholdChange}}
                  id="lottery-threshold"
                  min="1"
                  class="d-input"
                />
              </div>

              <div class="lottery-field">
                <label>人数不足时</label>
                <ComboBox
                  @content={{this.fallbackOptions}}
                  @value={{this.fallbackStrategy}}
                  @onChange={{this.onFallbackStrategyChange}}
                />
              </div>
            </form>
          {{else}}
            <div class="lottery-preview-container">
              <div class="lottery-preview">
                <h3>{{this.previewData.name}}</h3>
                <p><strong>奖品：</strong>{{this.previewData.prize}}</p>
                <p><strong>开奖时间：</strong>{{this.previewData.drawAt}}</p>
                <p><strong>获奖人数：</strong>{{this.previewData.winnerCount}}</p>
                <p><strong>参与门槛：</strong>{{this.previewData.participantThreshold}}</p>
              </div>
            </div>
          {{/unless}}
        </div>
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
