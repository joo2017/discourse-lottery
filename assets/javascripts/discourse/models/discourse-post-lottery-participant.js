import { tracked } from "@glimmer/tracking";
import User from "discourse/models/user";

export default class DiscoursePostLotteryParticipant {
  static create(args = {}) {
    return new DiscoursePostLotteryParticipant(args);
  }

  @tracked id;
  @tracked postId;
  @tracked postNumber;
  @tracked user;

  constructor(args = {}) {
    this.id = args.id;
    this.postId = args.post_id;
    this.postNumber = args.post_number;
    this.user = this.#initUserModel(args.user);
  }

  #initUserModel(user) {
    if (!user || user instanceof User) {
      return user;
    }
    return User.create(user);
  }
}
