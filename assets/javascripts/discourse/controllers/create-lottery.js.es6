import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default Controller.extend(ModalFunctionality, {
  prize: "",
  winnersCount: 1,
  endCondition: "time",
  endValue: 24,
  topicId: null,

  currentUser: service(),

  actions: {
    createLottery() {
      let lotteryData = {
        prize_description: this.prize,
        winners_count: this.winnersCount,
        end_condition: this.endCondition,
        end_value: this.endValue,
      };

      ajax(`/lottery/topics/${this.topicId}/lottery`, {
        type: "POST",
        data: { lottery: lotteryData }
      }).then(() => {
        this.send("closeModal");
      }).catch((error) => {
        // Handle error (e.g., display an error message)
      });
    }
  }
});
