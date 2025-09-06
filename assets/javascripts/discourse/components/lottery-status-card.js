import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class LotteryStatusCard extends Component {
  @service messageBus;
  @service currentUser;
  @tracked timeRemaining = null;
  @tracked currentParticipants = 0;

  constructor() {
    super(...arguments);
    this.startTimeTracking();
    this.setupRealtimeUpdates();
    // 模拟当前参与人数
    this.currentParticipants = Math.floor(Math.random() * 20) + 1;
  }

  get lottery() {
    return this.args.lottery;
  }

  get statusIcon() {
    const icons = {
      running: "clock",
      finished: "trophy",
      cancelled: "times-circle",
      locked: "lock"
    };
    return icons[this.lottery?.status] || "question";
  }

  get statusClass() {
    return `lottery-status-${this.lottery?.status || "unknown"}`;
  }

  get drawMethodText() {
    if (this.lottery?.draw_method === "fixed") {
      return I18n.t("discourse_lottery.card.draw_method_fixed");
    }
    return I18n.t("discourse_lottery.card.draw_method_random");
  }

  get backupStrategyText() {
    if (this.lottery?.backup_strategy === "cancel") {
      return I18n.t("discourse_lottery.form.backup_strategy_cancel");
    }
    return I18n.t("discourse_lottery.form.backup_strategy_continue");
  }

  get participantsProgress() {
    if (!this.lottery?.min_participants) return 0;
    return Math.min((this.currentParticipants / this.lottery.min_participants) * 100, 100);
  }

  get participantsStatus() {
    if (this.currentParticipants >= this.lottery?.min_participants) {
      return "sufficient";
    } else if (this.currentParticipants >= this.lottery?.min_participants * 0.7) {
      return "warning";
    }
    return "insufficient";
  }

  startTimeTracking() {
    if (!this.lottery?.draw_time) return;

    const updateTime = () => {
      const now = moment();
      const drawTime = moment(this.lottery.draw_time);
      
      if (drawTime.isBefore(now)) {
        this.timeRemaining = I18n.t("discourse_lottery.card.time_remaining_passed");
      } else {
        this.timeRemaining = drawTime.from(now);
      }
    };

    updateTime();
    this.timeUpdateInterval = setInterval(updateTime, 60000); // 每分钟更新一次
  }

  willDestroy() {
    super.willDestroy(...arguments);
    if (this.timeUpdateInterval) {
      clearInterval(this.timeUpdateInterval);
    }
    // 取消 MessageBus 订阅
    this.messageBus.unsubscribe('/lottery-updates');
  }

  setupRealtimeUpdates() {
    // 设置实时更新（暂时模拟）
    this.messageBus.subscribe('/lottery-updates', (data) => {
      if (data.lottery_id === this.lottery?.id) {
        // 更新参与人数等实时数据
        this.currentParticipants = data.current_participants || this.currentParticipants;
      }
    });
  }

  @action
  participateInLottery() {
    if (!this.currentUser) {
      // 提示用户登录
      this.appEvents.trigger("modal:show", "login");
      return;
    }

    // 模拟参与抽奖
    this.currentParticipants += 1;
    
    // 显示成功消息
    this.appEvents.trigger("modal-body:flash", {
      text: I18n.t("discourse_lottery.messages.participation_success"),
      messageClass: "success"
    });
  }

  @action
  viewLotteryDetails() {
    // 显示详细信息模态框
    if (this.args.onViewDetails) {
      this.args.onViewDetails(this.lottery);
    }
  }
}
