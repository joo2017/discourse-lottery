import { tracked } from "@glimmer/tracking";
import User from "discourse/models/user";

export default class DiscoursePostLotteryWinner {
  static create(args = {}) {
    return new DiscoursePostLotteryWinner(args);
  }

  @tracked id;
  @tracked postId;
  @tracked postNumber;
  @tracked wonAt;
  @tracked user;

  constructor(args = {}) {
    this.id = args.id;
    this.postId = args.post_id;
    this.postNumber = args.post_number;
    this.wonAt = args.won_at;
    this.user = this.#initUserModel(args.user);
  }

  #initUserModel(user) {
    if (!user || user instanceof User) {
      return user;
    }
    return User.create(user);
  }
}
