import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";

export default class LotteryInfo extends Component {
  get drawTime() {
    return moment(this.args.lottery.drawTime).tz(this.timezone);
  }

  get timezone() {
    return this.args.lottery.timezone || "UTC";
  }

  get timeRemaining() {
    if (this.args.lottery.expired) return null;

    const now = moment();
    const drawTime = this.drawTime;
    const diff = drawTime.diff(now);

    if (diff <= 0) return "即将开奖";

    const duration = moment.duration(diff);
    const days = Math.floor(duration.asDays());
    const hours = duration.hours();
    const minutes = duration.minutes();

    if (days > 0) return `${days}天${hours}小时后开奖`;
    if (hours > 0) return `${hours}小时${minutes}分钟后开奖`;
    return `${minutes}分钟后开奖`;
  }

  <template>
    <section class="lottery__section lottery-draw-info">
      <div class="lottery-prize">
        {{icon "gift"}}
        <div class="prize-details">
          <div class="prize-name">{{@lottery.prizeName}}</div>
          {{#if @lottery.prizeImage}}
            <div class="prize-image">
              <img src={{@lottery.prizeImage}} alt={{@lottery.prizeName}} />
            </div>
          {{/if}}
          {{#if @lottery.description}}
            <div class="prize-description">{{@lottery.description}}</div>
          {{/if}}
        </div>
      </div>

      <div class="lottery-timing">
        {{icon "clock"}}
        <div class="timing-details">
          <div class="draw-time">
            开奖时间：{{this.drawTime.format("YYYY-MM-DD HH:mm")}}
          </div>
          {{#if this.timeRemaining}}
            <div class="time-remaining">{{this.timeRemaining}}</div>
          {{/if}}
        </div>
      </div>

      <div class="lottery-rules">
        {{icon "info-circle"}}
        <div class="rules-details">
          <div class="winner-count">获奖人数：{{@lottery.winnerCount}}人</div>
          <div class="min-participants">参与门槛：{{@lottery.minParticipants}}人</div>
          <div class="draw-type">
            {{#if (eq @lottery.drawType "random")}}
              随机抽奖
            {{else}}
              指定楼层：{{@lottery.fixedFloors}}
            {{/if}}
          </div>
        </div>
      </div>
    </section>
  </template>
}
