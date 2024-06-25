import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default Controller.extend(ModalFunctionality, {
  prize: "",
  winnersCount: 1,
  endCondition: "time",
  endValue: 24,
  topicId: null,
  currentUser: service(),

  @action
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
      // 可能需要在这里添加逻辑来刷新或更新UI
    }).catch((error) => {
      popupAjaxError(error);
      this.flash(I18n.t("lottery.creation_failed"), "error");
    });
  }
});
