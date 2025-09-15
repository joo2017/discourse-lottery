import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class LotteryParticipants extends Component {
  @service modal;
  @service siteSettings;
  @service currentUser;

  @tracked participantsData = null;
  @tracked isLoadingParticipants = false;

  get hasParticipants() {
    return this.args.lottery?.participant_count > 0;
  }

  get participantCount() {
    return this.args.lottery?.participant_count || 0;
  }

  get participantsTitle() {
    return i18n("lottery.ui.participants_count", {
      count: this.participantCount,
    });
  }

  get thresholdMet() {
    return this.participantCount >= (this.args.lottery?.participant_threshold || 0);
  }

  get participantStatus() {
    if (!this.hasParticipants) {
      return "no-participants";
    }
    return this.thresholdMet ? "threshold-met" : "threshold-not-met";
  }

  get statusText() {
    if (!this.hasParticipants) {
      return i18n("lottery.ui.no_participants");
    }

    const threshold = this.args.lottery?.participant_threshold || 0;
    const current = this.participantCount;

    if (this.thresholdMet) {
      return i18n("lottery.ui.participants_joined", { count: current });
    } else {
      return i18n("lottery.ui.participants_needed", { 
        current: current, 
        needed: threshold - current 
      });
    }
  }

  get progressPercentage() {
    if (this.thresholdMet) return 100;
    const threshold = this.args.lottery?.participant_threshold || 1;
    return Math.min((this.participantCount / threshold) * 100, 100);
  }

  @action
  async loadParticipants() {
    if (!this.args.lottery?.id || this.isLoadingParticipants) return;

    this.isLoadingParticipants = true;
    try {
      const response = await ajax(`/lotteries/${this.args.lottery.id}/participants`);
      this.participantsData = response;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isLoadingParticipants = false;
    }
  }

  @action
  async showAllParticipants() {
    await this.loadParticipants();
    
    if (this.participantsData) {
      this.modal.show("lottery-participants-modal", {
        model: {
          lottery: this.args.lottery,
          participants: this.participantsData.participants,
          title: i18n("lottery.participants.title", { 
            name: this.args.lottery.name 
          })
        }
      });
    }
  }

  get canViewParticipants() {
    return (
      this.currentUser &&
      this.hasParticipants &&
      (this.currentUser.staff ||
        this.currentUser.id === this.args.lottery?.post?.user_id)
    );
  }

  <template>
    <section class="lottery__section lottery-participants">
      <div class="lottery-participants-container">
        <div class="lottery-participants-icon" title={{this.participantsTitle}}>
          {{icon "users"}}
          <span class="participants-count {{this.participantStatus}}">
            {{this.participantCount}}
          </span>
        </div>
        
        <div class="participants-info">
          <div class="participants-text">
            {{this.statusText}}
          </div>
          
          {{#if @lottery.participant_threshold}}
            <div class="threshold-progress">
              <div class="progress-bar">
                <div 
                  class="progress-fill {{if this.thresholdMet 'complete'}}"
                  style="width: {{this.progressPercentage}}%"
                ></div>
              </div>
              <div class="progress-text">
                {{this.participantCount}}/{{@lottery.participant_threshold}}
              </div>
            </div>
          {{/if}}
          
          {{#if this.canViewParticipants}}
            <button
              type="button"
              class="btn btn-small participants-detail-btn"
              {{on "click" this.showAllParticipants}}
              disabled={{this.isLoadingParticipants}}
            >
              {{#if this.isLoadingParticipants}}
                {{icon "spinner" class="fa-spin"}} 加载中...
              {{else}}
                {{icon "list"}} 查看详情
              {{/if}}
            </button>
          {{/if}}
        </div>
      </div>
    </section>
  </template>
}
