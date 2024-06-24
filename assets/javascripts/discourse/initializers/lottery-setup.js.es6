import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

export default {
  name: "lottery-setup",
  initialize() {
    withPluginApi("0.8.31", api => {
      api.addToolbarPopupMenuOptionsCallback(() => {
        return {
          action: "showLotteryModal",
          icon: "plus", // 尝试使用 "plus" 图标
          // 或者尝试这些选项：
          // icon: "cog",
          // icon: "random",
          // icon: "discourse-expand", // Discourse 特定图标
          label: "lottery.create",
          condition: composer => composer.get("topicFirstPost")
        };
      });

      api.modifyClass("controller:composer", {
        actions: {
          showLotteryModal() {
            showModal("create-lottery");
          }
        }
      });
    });
  }
};
