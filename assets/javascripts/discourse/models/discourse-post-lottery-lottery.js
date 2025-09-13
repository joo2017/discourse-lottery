import { tracked } from "@glimmer/tracking";
import EmberObject from "@ember/object";
import { TrackedArray } from "@ember-compat/tracked-built-ins";
import User from "discourse/models/user";
import DiscoursePostLotteryParticipant from "./discourse-post-lottery-participant";
import DiscoursePostLotteryWinner from "./discourse-post-lottery-winner";

export default class DiscoursePostLotteryLottery {
  static create(args = {}) {
    return new DiscoursePostLotteryLottery(args);
  }

  @tracked id;
  @tracked prizeName;
  @tracked prizeImage;
  @tracked description;
  @tracked drawTime;
  @tracked winnerCount;
  @tracked minParticipants;
  @tracked drawType;
  @tracked fixedFloors;
  @tracked fallbackStrategy;
  @tracked timezone;
  @tracked status;
  @tracked expired;
  @tracked running;
  @tracked finished;
  @tracked cancelled;
  @tracked totalParticipants;
  @tracked canActOnDiscoursePostLottery;
  @tracked canParticipate;
  @tracked currentUserParticipated;
  @tracked post;
  @tracked creator;
  @tracked _sampleParticipants;
  @tracked _winners;

  constructor(args = {}) {
    this.id = args.id;
    this.prizeName = args.prize_name;
    this.prizeImage = args.prize_image;
    this.description = args.description;
    this.drawTime = args.draw_time;
    this.winnerCount = args.winner_count;
    this.minParticipants = args.min_participants;
    this.drawType = args.draw_type;
    this.fixedFloors = args.fixed_floors;
    this.fallbackStrategy = args.fallback_strategy;
    this.timezone = args.timezone;
    this.status = args.status;
    this.expired = args.expired;
    this.running = args.running;
    this.finished = args.finished;
    this.cancelled = args.cancelled;
    this.totalParticipants = args.total_participants;
    this.canActOnDiscoursePostLottery = args.can_act_on_discourse_post_lottery;
    this.canParticipate = args.can_participate;
    this.currentUserParticipated = args.current_user_participated;
    this.post = args.post;
    this.creator = this.#initUserModel(args.creator);
    this.sampleParticipants = args.sample_participants || [];
    this.winners = args.winners || [];
  }

  get sampleParticipants() {
    return this._sampleParticipants;
  }

  set sampleParticipants(participants = []) {
    this._sampleParticipants = new TrackedArray(
      participants.map((p) => DiscoursePostLotteryParticipant.create(p))
    );
  }

  get winners() {
    return this._winners;
  }

  set winners(winners = []) {
    this._winners = new TrackedArray(
      winners.map((w) => DiscoursePostLotteryWinner.create(w))
    );
  }

  get isRunning() {
    return this.running;
  }

  get isFinished() {
    return this.finished;
  }

  get isCancelled() {
    return this.cancelled;
  }

  updateFromLottery(lottery) {
    this.prizeName = lottery.prizeName;
    this.prizeImage = lottery.prizeImage;
    this.description = lottery.description;
    this.drawTime = lottery.drawTime;
    this.status = lottery.status;
    this.expired = lottery.expired;
    this.running = lottery.running;
    this.finished = lottery.finished;
    this.cancelled = lottery.cancelled;
    this.totalParticipants = lottery.totalParticipants;
    this.canParticipate = lottery.canParticipate;
    this.currentUserParticipated = lottery.currentUserParticipated;
    this.sampleParticipants = lottery.sampleParticipants || [];
    this.winners = lottery.winners || [];
  }

  #initUserModel(user) {
    if (!user || user instanceof User) {
      return user;
    }
    return User.create(user);
  }
}
