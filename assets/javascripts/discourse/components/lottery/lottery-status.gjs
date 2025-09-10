import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import icon from "discourse/helpers/d-icon";

export default class LotteryStatus extends Component {
  get statusText() {
    const status = this.args.lottery?.status;
    if (!status) return i18n("lottery.status.unknown");
    
    return i18n(`lottery.status.${status}`);
  }

  get statusIcon() {
    const status = this.args.lottery?.status;
    switch (status) {
      case "running":
        return "clock";
      case "finished":
        return "check-circle";
      case "cancelled":
        return "times-circle";
      default:
        return "question-circle";
    }
  }

  get statusClass() {
    const status = this.args.lottery?.status;
    return `lottery-status status-${status || 'unknown'}`;
  }

  get isOverdue() {
    if (this.args.lottery?.status !== "running") return false;
    if (!this.args.lottery?.draw_at) return false;
    
    const drawTime = moment(this.args.lottery.draw_at);
    return drawTime.isBefore(moment());
  }

  get statusDescription() {
    const status = this.args.lottery?.status;
    const lottery = this.args.lottery;
    
    switch (status) {
      case "running":
        if (this.isOverdue) {
          return "开奖时间已过，等待系统处理";
        }
        return "抽奖进行中";
      
      case "finished":
        const winnersCount = lottery?.winners?.length || 0;
        if (winnersCount > 0) {
          return `已开奖，共 ${winnersCount} 名获奖者`;
        }
        return "抽奖已结束";
      
      case "cancelled":
        return "抽奖已取消";
      
      default:
        return "状态未知";
    }
  }

  get showParticipantProgress() {
    return (
      this.args.lottery?.status === "running" &&
      this.args.lottery?.participant_threshold > 0
    );
  }

  get participantProgress() {
    if (!this.showParticipantProgress) return null;
    
    const current = this.args.lottery?.participant_count || 0;
    const threshold = this.args.lottery?.participant_threshold || 0;
    
    return {
      current,
      threshold,
      percentage: Math.min((current / threshold) * 100, 100),
      met: current >= threshold
    };
  }

  <template>
    <div class={{this.statusClass}}>
      <div class="status-main">
        <span class="status-icon-wrapper">
          {{icon this.statusIcon class=(if this.isOverdue "overdue")}}
        </span>
        <span class="status-text">{{this.statusText}}</span>
      </div>
      
      {{#if this.statusDescription}}
        <div class="status-description">
          {{this.statusDescription}}
        </div>
      {{/if}}

      {{#if this.showParticipantProgress}}
        <div class="participant-progress-wrapper">
          <div class="progress-info">
            <span class="progress-label">参与进度:</span>
            <span class="progress-numbers">
              {{this.participantProgress.current}}/{{this.participantProgress.threshold}}
            </span>
          </div>
          
          <div class="progress-bar-container">
            <div 
              class="progress-bar {{if this.participantProgress.met 'complete'}}"
              style="width: {{this.participantProgress.percentage}}%"
            ></div>
          </div>

          {{#unless this.participantProgress.met}}
            <div class="progress-hint">
              还需 {{sub this.participantProgress.threshold this.participantProgress.current}} 人参与
            </div>
          {{/unless}}
        </div>
      {{/if}}

      {{#if this.isOverdue}}
        <div class="overdue-notice">
          {{icon "exclamation-triangle"}}
          <span>开奖时间已过，系统正在处理中...</span>
        </div>
      {{/if}}
    </div>
  </template>
}
