import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class LotteryStatus extends Component {
  @service currentUser;
  @service discoursePostLotteryApi;

  get canParticipate() {
    return this.currentUser &&
           this.args.lottery.isRunning &&
           !this.args.lottery.expired &&
           !this.hasParticipated;
  }

  get hasParticipated() {
    return this.args.lottery.currentUserParticipated;
  }

  @action
  async participateInLottery() {
    try {
      await this.discoursePostLotteryApi.participateInLottery(this.args.lottery);
      // 重新加载页面或更新状态
      window.location.reload();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if this.canParticipate}}
      <section class="lottery__section lottery-actions">
        <DButton
          @action={{this.participateInLottery}}
          @icon="dice"
          @label="参与抽奖"
          class="btn-primary participate-button"
        />
        <div class="participation-hint">
          回复本帖即可参与抽奖
        </div>
      </section>
    {{else if this.hasParticipated}}
      <section class="lottery__section lottery-actions">
        <div class="participated-status">
          {{icon "check-circle"}} 您已参与此次抽奖
        </div>
      </section>
    {{/if}}
  </template>
}
