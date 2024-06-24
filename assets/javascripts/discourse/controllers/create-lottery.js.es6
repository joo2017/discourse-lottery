import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  prize: "",
  winnersCount: 1,
  endCondition: "time",
  endValue: 24,

  actions: {
    createLottery() {
      // 这里添加创建抽奖的逻辑
      this.send("closeModal");
    }
  }
});
