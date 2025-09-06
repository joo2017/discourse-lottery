import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

export default class LotteryParticipantList extends Component {
  @service lotteryService;
  @tracked participants = [];
  @tracked isLoading = true;
  @tracked currentPage = 1;
  @tracked totalPages = 1;

  constructor() {
    super(...arguments);
    this.loadParticipants();
  }

  async loadParticipants() {
    if (!this.args.lotteryId) return;

    this.isLoading = true;
    try {
      const data = await this.lotteryService.getLotteryParticipants(this.args.lotteryId);
      this.participants = data.participants || [];
      this.totalPages = Math.ceil((data.total || 0) / 20);
    } catch (error) {
      console.error("加载参与者列表失败:", error);
    } finally {
      this.isLoading = false;
    }
  }

  @action
  async changePage(page) {
    this.currentPage = page;
    await this.loadParticipants();
  }

  @action
  async refreshList() {
    await this.loadParticipants();
  }

  get paginatedParticipants() {
    const startIndex = (this.currentPage - 1) * 20;
    return this.participants.slice(startIndex, startIndex + 20);
  }
}
