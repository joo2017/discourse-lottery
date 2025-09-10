import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";
import { i18n } from "discourse-i18n";
import { formatUsername } from "discourse/lib/utilities";
import { htmlSafe } from "@ember/template";
import avatar from "discourse/helpers/avatar";
import formatDate from "discourse/helpers/format-date";

export default class Lottery extends Component {
  @service ajax;
  @service messageBus;
  @service site;

  @tracked lottery = this.args.lottery;

  // Helper methods and getters
  formatDate = formatDate;
  formatUsername = formatUsername;
  avatar = avatar;

  get isMobile() {
    return this.site.mobileView;
  }

  get isRunning() { 
    return this.lottery.status === "running"; 
  }

  get isFinished() { 
    return this.lottery.status === "finished"; 
  }

  get isCancelled() { 
    return this.lottery.status === "cancelled"; 
  }

  get statusText() {
    return i18n(`lottery.status.${this.lottery.status}`);
  }

  get prizeHtml() {
    // Note: Assuming prize description is simple text for security.
    // If markdown is needed, a server-side cooking process would be required.
    return htmlSafe(this.lottery.prize);
  }

  get descriptionHtml() {
    return htmlSafe(this.lottery.description);
  }

  get fallbackStrategyText() {
    return i18n(`lottery.fallback_strategy.${this.lottery.fallback_strategy}`);
  }

  setupMessageBus = modifier(
    (element) => {
      const channel = `/lottery/${this.lottery.post.topic_id}`;
      this.messageBus.subscribe(channel, (msg) => {
        if (msg.id === this.lottery.id) {
          this.reloadLottery();
        }
      });

      return () => this.messageBus.unsubscribe(channel);
    },
    { eager: false }
  );

  @action
  async reloadLottery() {
    try {
      const result = await this.ajax(`/lotteries/${this.lottery.id}.json`);
      this.lottery = result.lottery;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("Failed to reload lottery data", error);
    }
  }

  <template>
    <div class="discourse-lottery" {{this.setupMessageBus}}>
      <div class="lottery-header">
        <span class="lottery-name">{{this.lottery.name}}</span>
        <span class="lottery-status {{this.lottery.status}}">{{this.statusText}}</span>
      </div>

      <div class="lottery-body">
        <div class="lottery-prize">
          <span class="label">{{i18n "lottery.ui.prize"}}</span>
          <span class="value">{{this.prizeHtml}}</span>
        </div>

        {{#if this.lottery.prize_image_url}}
          <div class="lottery-prize-image-wrapper">
            <img 
              src={{this.lottery.prize_image_url}} 
              class="lottery-prize-image" 
              alt={{i18n "lottery.ui.prize_image_alt"}}
            />
          </div>
        {{/if}}

        {{#if this.lottery.description}}
          <div class="lottery-description">
            <span class="label">{{i18n "lottery.ui.description"}}</span>
            <span class="value">{{this.descriptionHtml}}</span>
          </div>
        {{/if}}

        {{#if this.isRunning}}
          <div class="lottery-info">
            <div class="info-item">
              <span class="label">{{i18n "lottery.ui.draw_at"}}</span>
              <span class="value">{{this.formatDate this.lottery.draw_at format="medium-with-time"}}</span>
            </div>
            <div class="info-item">
              <span class="label">{{i18n "lottery.ui.winner_count"}}</span>
              <span class="value">{{this.lottery.winner_count}}</span>
            </div>
            <div class="info-item">
              <span class="label">{{i18n "lottery.ui.participant_threshold"}}</span>
              <span class="value">{{this.lottery.participant_threshold}}</span>
            </div>
            <div class="info-item">
              <span class="label">{{i18n "lottery.ui.fallback_strategy"}}</span>
              <span class="value">{{this.fallbackStrategyText}}</span>
            </div>
          </div>
        {{/if}}

        {{#if this.isFinished}}
          <div class="lottery-winners">
            <span class="label">{{i18n "lottery.ui.winners"}}</span>
            <ul class="winner-list">
              {{#each this.lottery.winners as |winner|}}
                <li>
                  <a href={{winner.path}} data-user-card={{winner.username}}>
                    {{this.avatar winner imageSize="small"}}
                    <span class="username">{{this.formatUsername winner.username}}</span>
                  </a>
                </li>
              {{/each}}
            </ul>
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
