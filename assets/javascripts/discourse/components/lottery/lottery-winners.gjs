import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq, gt } from "@ember/helper";
import icon from "discourse/helpers/d-icon";
import avatar from "discourse/helpers/avatar";
import { formatUsername } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

export default class LotteryWinners extends Component {
  @service modal;
  @service siteSettings;
  @service currentUser;

  formatUsername = formatUsername;
  avatar = avatar;

  get hasWinners() {
    return this.args.lottery?.winners && this.args.lottery.winners.length > 0;
  }

  get winners() {
    return this.args.lottery?.winners || [];
  }

  get winnersCount() {
    return this.winners.length;
  }

  get winnersTitle() {
    return i18n("lottery.ui.winners_count", {
      count: this.winnersCount,
    });
  }

  get displayWinners() {
    // 只显示前几名，如果获奖者很多的话
    const maxDisplay = 6;
    return this.winners.slice(0, maxDisplay);
  }

  get hasMoreWinners() {
    return this.winners.length > this.displayWinners.length;
  }

  get moreWinnersCount() {
    return this.winners.length - this.displayWinners.length;
  }

  get isLotteryFinished() {
    return this.args.lottery?.status === "finished";
  }

  @action
  showAllWinners() {
    this.modal.show("lottery-winners-modal", {
      model: {
        lottery: this.args.lottery,
        winners: this.winners,
        title: i18n("lottery.winners.title", { 
          name: this.args.lottery.name 
        })
      }
    });
  }

  @action
  navigateToPost(winner) {
    if (winner.post_url) {
      window.location.href = winner.post_url;
    } else if (this.args.lottery?.post?.topic_id && winner.post_number) {
      const topicId = this.args.lottery.post.topic_id;
      window.location.href = `/t/${topicId}/${winner.post_number}`;
    }
  }

  <template>
    {{#if this.hasWinners}}
      <section class="lottery__section lottery-winners">
        <div class="lottery-winners-container">
          <div class="lottery-winners-icon" title={{this.winnersTitle}}>
            {{icon "trophy"}}
            <span class="winners-count">{{this.winnersCount}}</span>
          </div>
          
          <div class="lottery-winners-content">
            <div class="winners-header">
              <span class="winners-label">
                {{i18n "lottery.ui.winners_announced"}}
              </span>
              {{#if this.hasMoreWinners}}
                <button
                  type="button"
                  class="btn btn-small show-all-winners-btn"
                  {{on "click" this.showAllWinners}}
                >
                  查看全部 ({{this.winnersCount}})
                </button>
              {{/if}}
            </div>

            <ul class="lottery-winners-list">
              {{#each this.displayWinners as |winner|}}
                <li class="lottery-winner" data-rank={{winner.rank}}>
                  <button
                    type="button"
                    class="winner-item-btn"
                    {{on "click" (fn this.navigateToPost winner)}}
                    title="点击跳转到中奖楼层"
                  >
                    <div class="winner-avatar">
                      {{this.avatar winner imageSize="small"}}
                      <div class="winner-flair">
                        {{#if (eq winner.rank 1)}}
                          {{icon "crown"}}
                        {{else}}
                          {{icon "trophy"}}
                        {{/if}}
                      </div>
                    </div>
                    
                    <div class="winner-info">
                      <span class="username">{{this.formatUsername winner.username}}</span>
                      <span class="post-info">#{{winner.post_number}}</span>
                      {{#if (gt this.winnersCount 1)}}
                        <span class="rank-info">第{{winner.rank}}名</span>
                      {{/if}}
                    </div>
                  </button>
                </li>
              {{/each}}
            </ul>

            {{#if this.hasMoreWinners}}
              <div class="more-winners-indicator">
                <button
                  type="button"
                  class="btn btn-small btn-default"
                  {{on "click" this.showAllWinners}}
                >
                  +{{this.moreWinnersCount}} 更多获奖者
                </button>
              </div>
            {{/if}}
          </div>
        </div>
      </section>
    {{/if}}
  </template>
}
