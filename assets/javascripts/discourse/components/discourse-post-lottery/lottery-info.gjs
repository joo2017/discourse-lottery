// assets/javascripts/discourse/components/discourse-post-lottery/lottery-info.gjs
import Component from "@glimmer/component";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class LotteryInfo extends Component {
  @service siteSettings;

  get formattedDrawTime() {
    if (!this.args.lottery.drawTime) return null;
    return moment(this.args.lottery.drawTime).format("YYYY-MM-DD HH:mm");
  }

  get statusText() {
    const status = this.args.lottery.status;
    return i18n(`discourse_lottery.status.${status}`);
  }

  <template>
    <div class="lottery-info-card">
      <div class="lottery-header">
        {{icon "gift"}}
        <h3 class="lottery-title">{{@lottery.name}}</h3>
      </div>
      
      <div class="lottery-details">
        {{#if this.formattedDrawTime}}
          <div class="lottery-draw-time">
            {{icon "clock"}}
            {{!-- 这是第26行 - 替换原来第22行的错误代码 --}}
            <span>{{i18n "discourse_lottery.draw_time"}}：{{this.formattedDrawTime}}</span>
          </div>
        {{/if}}
        
        <div class="lottery-status">
          {{icon "flag"}}
          <span>{{i18n "discourse_lottery.status_label"}}：{{this.statusText}}</span>
        </div>
        
        {{#if @lottery.prizeDescription}}
          <div class="lottery-prize">
            {{icon "trophy"}}
            <span>{{i18n "discourse_lottery.prize_label"}}：{{@lottery.prizeDescription}}</span>
          </div>
        {{/if}}

        {{#if @lottery.participantCount}}
          <div class="lottery-participants">
            {{icon "users"}}
            <span>{{i18n "discourse_lottery.participant_count" count=@lottery.participantCount}}</span>
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
