import { underscore } from "@ember/string";
import DiscoursePostLotteryAdapter from "./discourse-post-lottery-adapter";

export default class DiscoursePostLotteryLottery extends DiscoursePostLotteryAdapter {
  pathFor(store, type, findArgs) {
    const path =
      this.basePath(store, type, findArgs) +
      underscore(store.pluralize(this.apiNameFor(type)));
    return this.appendQueryParams(path, findArgs);
  }

  apiNameFor() {
    return "lottery";
  }
}
