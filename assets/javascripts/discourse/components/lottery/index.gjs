import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import PluginOutlet from "discourse/components/plugin-outlet";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import lazyHash from "discourse/helpers/lazy-hash";
import replaceEmoji from "discourse/helpers/replace-emoji";
import routeAction from "discourse/helpers/route-action";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import LotteryDates from "./lottery-dates";
import LotteryDescription from "./lottery-description";
import LotteryParticipants from "./lottery-participants";
import LotteryWinners from "./lottery-winners";
import LotteryPrize from "./lottery-prize";
import LotteryStatus from "./lottery-status";
import LotteryMoreMenu from "./lottery-more-menu";

const StatusSeparator = <template>
  <span class="separator">·</span>
</template>;

const InfoSection = <template>
  <section class="lottery__section" ...attributes>
    {{#if @icon}}
      {{icon @icon}}
    {{/if}}
    {{yield}}
  </section>
</template>;

export default class LotteryIndex extends Component {
  @service currentUser;
  @service messageBus;
  @service modal;
  @service router;

  @tracked lottery = null;
  @tracked isLoading = false;

  constructor() {
    super(...arguments);
    this.lottery = this.args.lottery;
    this.setupMessageBus();
  }

  setupMessageBus = modifier(() => {
    if (!this.lottery?.post?.topic_id) return;
    
    const path = `/lottery/${this.lottery.post.topic_id}`;
    this.messageBus.subscribe(path, (msg) => {
      if (msg.id === this.lottery?.id) {
        this.handleLotteryUpdate(msg);
      }
    });

    return () => this.messageBus.unsubscribe(path);
  });

  @action
  async handleLotteryUpdate(msg) {
    try {
      const response = await ajax(`/lotteries/${msg.id}`);
      this.lottery = response.lottery;
    } catch (error) {
      console.error("Failed to update lottery:", error);
    }
  }

  @action
  async refreshLottery() {
    if (!this.lottery?.id) return;
    
    this.isLoading = true;
    try {
      const response = await ajax(`/lotteries/${this.lottery.id}`);
      this.lottery = response.lottery;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isLoading = false;
    }
  }

  get localStartsAtTime() {
    if (!this.lottery?.draw_at) return null;
    return moment(this.lottery.draw_at);
  }

  get startsAtMonth() {
    return this.localStartsAtTime?.format("MMM") || "";
  }

  get startsAtDay() {
    return this.localStartsAtTime?.format("D") || "";
  }

  get lotteryName() {
    return this.lottery?.name || "抽奖活动";
  }

  get isRunning() {
    return this.lottery?.status === "running";
  }

  get isFinished() {
    return this.lottery?.status === "finished";
  }

  get isCancelled() {
    return this.lottery?.status === "cancelled";
  }

  get canActOnLottery() {
    return (
      this.currentUser &&
      this.lottery?.post &&
      (this.currentUser.staff ||
        this.currentUser.id === this.lottery.post.user_id)
    );
  }

  get statusClass() {
    return `status-${this.lottery?.status || 'unknown'}`;
  }

  <template>
    <div
      class={{concatClass
        "discourse-lottery"
        (if @lottery "is-loaded" "is-loading")
        (if @lottery "has-lottery")
        this.statusClass
      }}
    >
      <div class="discourse-lottery-widget">
        {{#if @lottery}}
          <header class="lottery-header" {{this.setupMessageBus}}>
            <div class="lottery-date">
              <div class="month">{{this.startsAtMonth}}</div>
              <div class="day">{{this.startsAtDay}}</div>
            </div>
            <div class="lottery-info">
              <span class="name">
                {{replaceEmoji this.lotteryName}}
              </span>
              <div class="status-and-info">
                <PluginOutlet
                  @name="lottery-status-and-info"
                  @outletArgs={{lazyHash
                    lottery=@lottery
                    Separator=StatusSeparator
                    Status=(component LotteryStatus lottery=@lottery)
                  }}
                >
                  <LotteryStatus @lottery={{@lottery}} />
                  {{#if @lottery.prize}}
                    <StatusSeparator />
                    <span class="prize-info">{{@lottery.prize}}</span>
                  {{/if}}
                </PluginOutlet>
              </div>
            </div>

            <LotteryMoreMenu
              @lottery={{@lottery}}
              @canActOnLottery={{this.canActOnLottery}}
              @onLotteryUpdated={{this.refreshLottery}}
              @composePrivateMessage={{routeAction "composePrivateMessage"}}
            />
          </header>

          <PluginOutlet
            @name="lottery-info-sections"
            @outletArgs={{lazyHash
              lottery=@lottery
              Section=(component InfoSection lottery=@lottery)
              Dates=(component LotteryDates lottery=@lottery)
              Description=(component LotteryDescription description=@lottery.description)
              Prize=(component LotteryPrize lottery=@lottery)
              Participants=(component LotteryParticipants lottery=@lottery)
              Winners=(component LotteryWinners lottery=@lottery)
            }}
          >
            <LotteryDates @lottery={{@lottery}} />
            
            {{#if @lottery.description}}
              <LotteryDescription @description={{@lottery.description}} />
            {{/if}}

            {{#if @lottery.prize_image_url}}
              <LotteryPrize @lottery={{@lottery}} />
            {{/if}}

            <InfoSection @icon="users">
              <span class="threshold-info">
                最少参与人数: {{@lottery.participant_threshold}}
              </span>
              <span class="separator">·</span>
              <span class="winner-count">
                获奖人数: {{@lottery.winner_count}}
              </span>
              {{#if @lottery.specified_winners}}
                <span class="separator">·</span>
                <span class="strategy-info">指定楼层开奖</span>
              {{else}}
                <span class="separator">·</span>
                <span class="strategy-info">随机开奖</span>
              {{/if}}
            </InfoSection>

            <LotteryParticipants @lottery={{@lottery}} />

            {{#if this.isFinished}}
              <LotteryWinners @lottery={{@lottery}} />
            {{/if}}
          </PluginOutlet>
        {{else}}
          <div class="lottery-placeholder">
            {{#if this.isLoading}}
              {{icon "spinner" class="fa-spin"}} 正在加载抽奖信息...
            {{else}}
              抽奖信息不可用
            {{/if}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
