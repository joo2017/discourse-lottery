import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscoursePostLotteryLottery from "discourse/plugins/discourse-lottery/discourse/models/discourse-post-lottery-lottery";

export default class DiscoursePostLotteryApi extends Service {
  async lottery(id) {
    const result = await this.#getRequest(`/lotteries/${id}`);
    return DiscoursePostLotteryLottery.create(result.lottery);
  }

  async participateInLottery(lottery) {
    const result = await this.#postRequest(`/lotteries/${lottery.id}/participate`);
    return result;
  }

  get #basePath() {
    return "/discourse-post-lottery";
  }

  #getRequest(endpoint, data = {}) {
    return ajax(`${this.#basePath}${endpoint}`, {
      type: "GET",
      data,
    });
  }

  #postRequest(endpoint, data = {}) {
    return ajax(`${this.#basePath}${endpoint}`, {
      type: "POST",
      data,
    });
  }
}
