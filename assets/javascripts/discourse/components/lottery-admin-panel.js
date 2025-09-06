import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

export default class LotteryAdminPanel extends Component {
  @service store;
  @service dialog;
  @tracked activeLotteries = [];
  @tracked completedLotteries = [];
  @tracked isLoading = true;

  constructor() {
    super(...arguments);
    this.loadLotteries();
  }

  async loadLotteries() {
    this.isLoading = true;
    try {
      // 模拟加载抽奖数据
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      this.activeLotteries = [
        {
          id: 1,
          name: "春节大抽奖",
          status: "running",
          participants_count: 15,
          min_participants: 10,
          draw_time: "2025-02-01T20:00:00Z"
        },
        {
          id: 2,
          name: "周年庆抽奖",
          status: "running", 
          participants_count: 8,
          min_participants: 20,
          draw_time: "2025-02-15T18:00:00Z"
        }
      ];

      this.completedLotteries = [
        {
          id: 3,
          name: "新年抽奖",
          status: "finished",
          winners: ["user1", "user2"],
          completed_at: "2025-01-01T20:00:00Z"
        }
      ];
    } catch (error) {
      console.error("加载抽奖数据失败:", error);
    } finally {
      this.isLoading = false;
    }
  }

  @action
  async cancelLottery(lottery) {
    const confirmed = await this.dialog.confirm({
      message: `确定要取消抽奖"${lottery.name}"吗？`,
      didConfirm: () => true,
      didCancel: () => false
    });

    if (confirmed) {
      try {
        // 模拟取消抽奖 API 调用
        await new Promise(resolve => setTimeout(resolve, 500));
        
        lottery.status = "cancelled";
        this.activeLotteries = this.activeLotteries.filter(l => l.id !== lottery.id);
        
        this.dialog.alert("抽奖已成功取消");
      } catch (error) {
        this.dialog.alert("取消抽奖失败，请重试");
      }
    }
  }

  @action
  async forceExecuteLottery(lottery) {
    const confirmed = await this.dialog.confirm({
      message: `确定要立即执行抽奖"${lottery.name}"吗？当前参与人数为 ${lottery.participants_count} 人。`,
      didConfirm: () => true,
      didCancel: () => false
    });

    if (confirmed) {
      try {
        // 模拟立即执行抽奖 API 调用
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        lottery.status = "finished";
        this.activeLotteries = this.activeLotteries.filter(l => l.id !== lottery.id);
        this.completedLotteries.unshift(lottery);
        
        this.dialog.alert("抽奖已成功执行");
      } catch (error) {
        this.dialog.alert("执行抽奖失败，请重试");
      }
    }
  }

  @action
  viewLotteryDetails(lottery) {
    // 显示抽奖详情模态框
    this.modal.show("lottery-details", { lottery });
  }
}
