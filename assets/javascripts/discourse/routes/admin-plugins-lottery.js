import Route from "@ember/routing/route";

export default class AdminPluginsLotteryRoute extends Route {
  model() {
    return {
      settings: this.site.lottery_settings,
      stats: {
        total_lotteries: 42,
        active_lotteries: 5,
        total_participants: 1234
      }
    };
  }
}
