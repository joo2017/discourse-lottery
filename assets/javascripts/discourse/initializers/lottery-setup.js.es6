import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

export default {
  name: "lottery-setup",
  initialize() {
    withPluginApi("0.8.31", api => {
      api.addToolbarPopupMenuOptionsCallback(() => {
        return {
          action: "showLotteryModal",
          icon: "gift",
          label: "lottery.create",
          condition: composer => composer.get("topicFirstPost")
        };
      });

      api.modifyClass("controller:composer", {
        actions: {
          showLotteryModal() {
            showModal("create-lottery", { model: this.model }).setProperties({
              topicId: this.model.id
            });
          }
        }
      });
    });
  }
};
