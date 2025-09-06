import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class LotteryService extends Service {
  @tracked activeLotteries = [];
  @tracked userParticipations = [];

  async createLottery(lotteryData) {
    // 模拟 API 调用
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        if (lotteryData.activityName.includes("error")) {
          reject(new Error("模拟创建失败"));
        } else {
          const lottery = {
            id: Date.now(),
            ...lotteryData,
            status: "running",
            created_at: new Date().toISOString()
          };
          this.activeLotteries.push(lottery);
          resolve(lottery);
        }
      }, 1000);
    });
  }

  async updateLottery(lotteryId, updateData) {
    // 模拟更新操作
    return new Promise((resolve) => {
      setTimeout(() => {
        const lottery = this.activeLotteries.find(l => l.id === lotteryId);
        if (lottery) {
          Object.assign(lottery, updateData);
        }
        resolve(lottery);
      }, 500);
    });
  }

  async participateInLottery(lotteryId) {
    // 模拟参与抽奖
    return new Promise((resolve) => {
      setTimeout(() => {
        this.userParticipations.push({
          lottery_id: lotteryId,
          participated_at: new Date().toISOString()
        });
        resolve(true);
      }, 300);
    });
  }

  async getLotteryParticipants(lotteryId) {
    // 模拟获取参与者列表
    return new Promise((resolve) => {
      setTimeout(() => {
        const participants = Array.from({ length: Math.floor(Math.random() * 20) + 1 }, (_, i) => ({
          id: i + 1,
          username: `user${i + 1}`,
          avatar_template: "/images/avatar.png",
          floor_number: i + 2
        }));
        resolve(participants);
      }, 500);
    });
  }

  hasUserParticipated(lotteryId) {
    return this.userParticipations.some(p => p.lottery_id === lotteryId);
  }
}
