import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeLottery(api) {
  api.modifyClass("controller:composer", {
    pluginId: "discourse-lottery",
    actions: {
      showLotteryModal() {
        showModal("create-lottery", { model: this.model });
      }
    }
  });

  api.addToolbarPopupMenuOptionsCallback(() => {
    return {
      action: "showLotteryModal",
      icon: "gift",
      label: "lottery.create",
      condition: (composer) => composer.get("canCreateLottery")
    };
  });

  api.modifyClass("model:composer", {
    pluginId: "discourse-lottery",
    canCreateLottery: function() {
      return this.get("topicFirstPost") && !this.get("topic.lottery");
    }.property("topicFirstPost", "topic.lottery"),

    createLottery(lotteryOptions) {
      this.set("lottery", lotteryOptions);
    }
  });
}

export default {
  name: "lottery-setup",
  initialize() {
    withPluginApi("0.8.31", initializeLottery);
  }
};
