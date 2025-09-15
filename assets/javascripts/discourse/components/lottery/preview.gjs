import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import icon from "discourse/helpers/d-icon";

export default class LotteryPreview extends Component {
  get statusText() {
    return i18n("lottery.status.running");
  }

  get fallbackStrategyText() {
    return i18n(`lottery.fallback_strategy.${this.args.fallbackStrategy || 'continue'}`);
  }

  <template>
    <div class="discourse-lottery lottery-preview">
      <div class="lottery-header">
        <span class="lottery-name">{{@name}} (预览)</span>
        <span class="lottery-status running">{{this.statusText}}</span>
      </div>
      <div class="lottery-body">
        <div class="lottery-prize">
          <span class="label">{{i18n "lottery.ui.prize"}}</span>
          <span class="value">{{@prize}}</span>
        </div>
        {{#if @prizeImageUrl}}
          <div class="lottery-prize-image-wrapper">
            <img 
              src={{@prizeImageUrl}} 
              class="lottery-prize-image" 
              alt={{i18n "lottery.ui.prize_image_alt"}}
            />
          </div>
        {{/if}}
        {{#if @description}}
          <div class="lottery-description">
            <span class="label">{{i18n "lottery.ui.description"}}</span>
            <span class="value">{{@description}}</span>
          </div>
        {{/if}}
        <div class="lottery-info">
          <div class="info-item">
            <span class="label">{{i18n "lottery.ui.draw_at"}}</span>
            <span class="value">{{@drawAt}}</span>
          </div>
          <div class="info-item">
            <span class="label">{{i18n "lottery.ui.winner_count"}}</span>
            <span class="value">{{@winnerCount}}</span>
          </div>
          <div class="info-item">
            <span class="label">{{i18n "lottery.ui.participant_threshold"}}</span>
            <span class="value">{{@participantThreshold}}</span>
          </div>
          <div class="info-item">
            <span class="label">{{i18n "lottery.ui.fallback_strategy"}}</span>
            <span class="value">{{this.fallbackStrategyText}}</span>
          </div>
        </div>
      </div>
    </div>
  </template>
}
