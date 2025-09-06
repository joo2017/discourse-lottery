import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

export default class LotteryPreview extends Component {
  @tracked mockWinners = [];

  constructor() {
    super(...arguments);
    this.generateMockWinners();
  }

  get lottery() {
    return this.args.lottery;
  }

  get previewData() {
    return {
      ...this.lottery,
      status: "finished", // 预览时显示为已完成状态
      current_participants: Math.max(this.lottery.min_participants + 2, 15),
      winners: this.mockWinners
    };
  }

  generateMockWinners() {
    const winnerCount = this.lottery?.effectiveWinnerCount || 1;
    const mockUsers = [
      { username: "lucky_user", avatar_template: "/images/avatar.png" },
      { username: "winner123", avatar_template: "/images/avatar.png" },
      { username: "fortunate_one", avatar_template: "/images/avatar.png" },
      { username: "prize_hunter", avatar_template: "/images/avatar.png" },
      { username: "random_winner", avatar_template: "/images/avatar.png" }
    ];

    this.mockWinners = [];
    for (let i = 0; i < winnerCount && i < mockUsers.length; i++) {
      this.mockWinners.push({
        user: mockUsers[i],
        floor_number: this.lottery?.draw_method === "fixed" 
          ? this.parseFixedFloors()[i] 
          : Math.floor(Math.random() * 50) + 2
      });
    }
  }

  parseFixedFloors() {
    if (!this.lottery?.fixedFloors) return [];
    return this.lottery.fixedFloors
      .split(",")
      .map(floor => parseInt(floor.trim()))
      .filter(floor => !isNaN(floor) && floor > 0);
  }
}

// assets/javascripts/discourse/components/lottery-form-field.js.es6
import Component from "@glimmer/component";
import { action } from "@ember/object";

export default class LotteryFormField extends Component {
  get fieldId() {
    return `lottery-field-${this.args.name}`;
  }

  get hasError() {
    return this.args.errors && this.args.errors[this.args.name];
  }

  get errorMessage() {
    return this.hasError ? this.args.errors[this.args.name] : null;
  }

  get fieldClass() {
    let classes = "lottery-form-field";
    if (this.hasError) classes += " has-error";
    if (this.args.required) classes += " required";
    return classes;
  }

  @action
  handleInput(event) {
    const value = event.target.value;
    if (this.args.onInput) {
      this.args.onInput(this.args.name, value);
    }
  }

  @action
  handleChange(event) {
    const value = event.target.value;
    if (this.args.onChange) {
      this.args.onChange(this.args.name, value);
    }
  }
}
