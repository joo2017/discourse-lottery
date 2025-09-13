import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import avatar from "discourse/helpers/avatar";

export default class LotteryParticipants extends Component {
  get participantCount() {
    return this.args.lottery.totalParticipants || 0;
  }

  get participantsTitle() {
    return `${this.participantCount}人参与`;
  }

  get canMeetRequirement() {
    return this.participantCount >= this.args.lottery.minParticipants;
  }

  <template>
    <section class="lottery__section lottery-participants">
      <div class="lottery-participants-container">
        <div class="lottery-participants-icon" title={{this.participantsTitle}}>
          {{icon "users"}}
          <span class="participant-count {{if this.canMeetRequirement "sufficient" "insufficient"}}">
            {{this.participantCount}} / {{@lottery.minParticipants}}
          </span>
        </div>

        {{#if @lottery.sampleParticipants}}
          <ul class="lottery-participants-avatars">
            {{#each @lottery.sampleParticipants as |participant|}}
              <li class="lottery-participant">
                <a class="topic-participant-avatar" data-user-card={{participant.user.username}}>
                  {{avatar participant.user imageSize="large"}}
                </a>
              </li>
            {{/each}}
          </ul>
        {{/if}}

        <div class="participation-status">
          {{#if this.canMeetRequirement}}
            <span class="status-ok">{{icon "check"}} 满足开奖条件</span>
          {{else}}
            <span class="status-warn">{{icon "exclamation-triangle"}} 还需 {{sub @lottery.minParticipants this.participantCount}} 人参与</span>
          {{/if}}
        </div>
      </div>
    </section>
  </template>
}
