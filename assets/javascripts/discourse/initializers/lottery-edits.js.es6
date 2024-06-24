import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeLottery(api) {
  api.modifyClass("controller:topic", {
    pluginId: "discourse-lottery",
    actions: {
      createLottery() {
        showModal("create-lottery", { model: this.model });
      }
    }
  });

  api.addPostMenuButton("lottery", (post) => {
    if (post.post_number === 1 && !post.get("topic.lottery")) {
      return {
        action: "createLottery",
        icon: "gift",
        className: "lottery-button",
        title: "lottery.create"
      };
    }
  });
}

export default {
  name: "lottery-setup",
  initialize() {
    withPluginApi("0.8.31", initializeLottery);
  }
};
