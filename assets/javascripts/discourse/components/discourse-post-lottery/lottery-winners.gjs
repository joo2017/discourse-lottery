import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import avatar from "discourse/helpers/avatar";
import { add } from "ember-math-helpers";
export default class LotteryWinners extends Component {
  <template>
    {{#if @lottery.winners}}
      <section class="lottery__section lottery-winners">
        <div class="winners-header">
          {{icon "trophy"}}
          <h3>🎉 中奖名单 🎉</h3>
        </div>

        <ul class="winners-list">
          {{#each @lottery.winners as |winner index|}}
            <li class="winner-item">
              <div class="winner-rank">第{{add index 1}}名</div>
              <div class="winner-info">
                <a class="winner-avatar" data-user-card={{winner.user.username}}>
                  {{avatar winner.user imageSize="medium"}}
                </a>
                <div class="winner-details">
                  <div class="winner-username">@{{winner.user.username}}</div>
                  <div class="winner-floor">{{winner.postNumber}}楼</div>
                </div>
              </div>
              <div class="winner-badge">
                {{icon "trophy"}}
              </div>
            </li>
          {{/each}}
        </ul>
      </section>
    {{/if}}
  </template>
}
