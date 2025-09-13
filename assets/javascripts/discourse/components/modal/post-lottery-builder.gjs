import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input, Textarea } from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import DateTimeInput from "discourse/components/date-time-input";
import RadioButton from "discourse/components/radio-button";
import { i18n } from "discourse-i18n";

export default class PostLotteryBuilder extends Component {
  @service siteSettings;
  @service store;

  @tracked flash = null;

  get lottery() {
    return this.args.model.lottery;
  }

  @action
  createLottery() {
    if (!this.lottery.draw_time) {
      this.args.closeModal();
      return;
    }

    const lotteryParams = this.buildParams();
    const markdownParams = [];
    
    Object.keys(lotteryParams).forEach((key) => {
      let value = lotteryParams[key];
      if (value) {
        markdownParams.push(`${key}="${value}"`);
      }
    });

    this.args.model.toolbarEvent.addText(
      `[lottery ${markdownParams.join(" ")}]\n[/lottery]`
    );
    this.args.closeModal();
  }

  buildParams() {
    const params = {};
    
    if (this.lottery.name) params.name = this.lottery.name;
    if (this.lottery.prize_description) params.prize = this.lottery.prize_description;
    if (this.lottery.draw_time) params.drawTime = moment(this.lottery.draw_time).format("YYYY-MM-DD HH:mm");
    if (this.lottery.winner_count) params.winners = this.lottery.winner_count;
    if (this.lottery.min_participants) params.minParticipants = this.lottery.min_participants;
    if (this.lottery.draw_method) params.method = this.lottery.draw_method;
    if (this.lottery.backup_strategy) params.backup = this.lottery.backup_strategy;
    if (this.lottery.specified_floors) params.floors = this.lottery.specified_floors;
    if (this.lottery.description) params.description = this.lottery.description;

    return params;
  }

  <template>
    <DModal
      @title={{i18n "discourse_lottery.builder_modal.create_lottery_title"}}
      @closeModal={{@closeModal}}
      @flash={{this.flash}}
      class="post-lottery-builder-modal"
    >
      <:body>
        <form>
          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.name.label"}}</label>
            <Input @value={{this.lottery.name}} placeholder={{i18n "discourse_lottery.builder_modal.name.placeholder"}} />
          </div>

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.prize.label"}}</label>
            <Input @value={{this.lottery.prize_description}} placeholder={{i18n "discourse_lottery.builder_modal.prize.placeholder"}} />
          </div>

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.draw_time.label"}}</label>
            <DateTimeInput @date={{this.lottery.draw_time}} @onChange={{fn (mut this.lottery.draw_time)}} />
          </div>

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.winner_count.label"}}</label>
            <Input @type="number" @value={{this.lottery.winner_count}} min="1" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.min_participants.label"}}</label>
            <Input @type="number" @value={{this.lottery.min_participants}} min="1" />
          </div>

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.method.label"}}</label>
            <RadioButton @name="method" @value="random" @selection={{this.lottery.draw_method}} @onChange={{fn (mut this.lottery.draw_method)}} />
            <span>{{i18n "discourse_lottery.builder_modal.method.random"}}</span>
            <br>
            <RadioButton @name="method" @value="floors" @selection={{this.lottery.draw_method}} @onChange={{fn (mut this.lottery.draw_method)}} />
            <span>{{i18n "discourse_lottery.builder_modal.method.floors"}}</span>
          </div>

          {{#if (eq this.lottery.draw_method "floors")}}
            <div class="lottery-field">
              <label>{{i18n "discourse_lottery.builder_modal.floors.label"}}</label>
              <Input @value={{this.lottery.specified_floors}} placeholder={{i18n "discourse_lottery.builder_modal.floors.placeholder"}} />
            </div>
          {{/if}}

          <div class="lottery-field">
            <label>{{i18n "discourse_lottery.builder_modal.description.label"}}</label>
            <Textarea @value={{this.lottery.description}} placeholder={{i18n "discourse_lottery.builder_modal.description.placeholder"}} />
          </div>
        </form>
      </:body>
      <:footer>
        <DButton
          class="btn-primary"
          @label="discourse_lottery.builder_modal.create"
          @icon="gift"
          @action={{this.createLottery}}
        />
      </:footer>
    </DModal>
  </template>
}
