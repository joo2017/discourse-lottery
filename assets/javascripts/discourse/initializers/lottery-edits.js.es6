import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeLottery(api) {
  api.modifyClass("controller:topic", {
    actions: {
      createLottery() {
        showModal("create-lottery", { model: this.model });
      }
    }
  });

  api.addPostMenuButton("lottery", (postModel) => {
    if (postModel.get("firstPost") && !postModel.get("topic.lottery")) {
      return {
        action: "createLottery",
        icon: "gift",
        label: "lottery.create"
      };
    }
  });
}

export default {
  name: "lottery-edits",
  initialize() {
    withPluginApi("0.8.31", initializeLottery);
  }
};
