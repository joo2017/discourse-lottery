import Component from "@glimmer/component";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import PluginOutlet from "discourse/components/plugin-outlet";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import lazyHash from "discourse/helpers/lazy-hash";
import replaceEmoji from "discourse/helpers/replace-emoji";
import LotteryInfo from "./lottery-info";
import LotteryParticipants from "./lottery-participants";
import LotteryStatus from "./lottery-status";
import LotteryWinners from "./lottery-winners";
import MoreMenu from "./more-menu";

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

export default class DiscoursePostLottery extends Component {
  @service currentUser;
  @service discoursePostLotteryApi;
  @service messageBus;

  setupMessageBus = modifier(() => {
    const { lottery } = this.args;
    const path = `/discourse-post-lottery/${lottery.post.topic.id}`;
    this.messageBus.subscribe(path, async (msg) => {
      const lotteryData = await this.discoursePostLotteryApi.lottery(msg.id);
      lottery.updateFromLottery(lotteryData);
    });

    return () => this.messageBus.unsubscribe(path);
  });

  get localDrawTime() {
    let time = moment(this.args.lottery.drawTime);
    if (this.args.lottery.timezone) {
      time = time.tz(this.args.lottery.timezone);
    }
    return time;
  }

  get drawMonth() {
    return this.localDrawTime.format("MMM");
  }

  get drawDay() {
    return this.localDrawTime.format("D");
  }

  get lotteryName() {
    return this.args.lottery.prizeName || this.args.lottery.post.topic.title;
  }

  get canActOnLottery() {
    return this.currentUser && this.args.lottery.canActOnDiscoursePostLottery;
  }

  get statusIcon() {
    if (this.args.lottery.isFinished) return "trophy";
    if (this.args.lottery.isCancelled) return "times-circle";
    if (this.args.lottery.isRunning) return "dice";
    return "gift";
  }

  get statusColor() {
    if (this.args.lottery.isFinished) return "success";
    if (this.args.lottery.isCancelled) return "danger";
    if (this.args.lottery.isRunning) return "primary";
    return "primary";
  }

  <template>
    <div
      class={{concatClass
        "discourse-post-lottery"
        (if @lottery "is-loaded" "is-loading")
      }}
    >
      <div class="discourse-post-lottery-widget">
        {{#if @lottery}}
          <header class="lottery-header" {{this.setupMessageBus}}>
            <div class="lottery-date">
              <div class="month">{{this.drawMonth}}</div>
              <div class="day">{{this.drawDay}}</div>
            </div>
            <div class="lottery-info">
              <span class="name">
                {{icon this.statusIcon}}
                {{replaceEmoji this.lotteryName}}
              </span>
              <div class="status-and-creator">
                <span class="status {{this.statusColor}}">
                  {{#if @lottery.isFinished}}
                    已开奖
                  {{else if @lottery.isCancelled}}
                    已取消
                  {{else if @lottery.expired}}
                    等待开奖
                  {{else}}
                    进行中
                  {{/if}}
                </span>
                <StatusSeparator />
                <span class="creator">
                  创建者：{{@lottery.creator.username}}
                </span>
              </div>
            </div>

            <MoreMenu
              @lottery={{@lottery}}
              @canActOnLottery={{this.canActOnLottery}}
            />
          </header>

          <PluginOutlet
            @name="discourse-post-lottery-info"
            @outletArgs={{lazyHash
              lottery=@lottery
              Section=(component InfoSection)
              LotteryInfo=(component LotteryInfo lottery=@lottery)
              LotteryParticipants=(component LotteryParticipants lottery=@lottery)
              LotteryWinners=(component LotteryWinners lottery=@lottery)
              LotteryStatus=(component LotteryStatus lottery=@lottery)
            }}
          >
            <LotteryInfo @lottery={{@lottery}} />
            <LotteryParticipants @lottery={{@lottery}} />
            {{#if @lottery.isFinished}}
              <LotteryWinners @lottery={{@lottery}} />
            {{/if}}
            {{#if @lottery.canParticipate}}
              <LotteryStatus @lottery={{@lottery}} />
            {{/if}}
          </PluginOutlet>
        {{/if}}
      </div>
    </div>
  </template>
}
