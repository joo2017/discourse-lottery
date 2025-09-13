import RestAdapter from "discourse/adapters/rest";

export default class DiscoursePostLotteryAdapter extends RestAdapter {
  basePath() {
    return "/discourse-post-lottery/";
  }
}
