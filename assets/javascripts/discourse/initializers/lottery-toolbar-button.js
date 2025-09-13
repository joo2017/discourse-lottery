import { withPluginApi } from "discourse/lib/plugin-api";
import LotteryBuilder from "../components/modal/lottery-builder";
import Lottery from "../models/lottery";

function initializeLotteryToolbar(api) {
  const currentUser = api.getCurrentUser();
  const modal = api.container.lookup("service:modal");

  api.addComposerToolbarPopupMenuOption({
    icon: "trophy",
    label: "lottery.builder.attach",

    action: (toolbarEvent) => {
      const lottery = Lottery.create();
      modal.show(LotteryBuilder, {
        model: {
          lottery: lottery,
          toolbarEvent: toolbarEvent,
        },
      });
    },

    condition: (composer) => {
      if (!currentUser) {
        return false;
      }
      const composerModel = composer.model;
      return (
        composerModel &&
        !composerModel.replyingToTopic &&
        (composerModel.topicFirstPost ||
          composerModel.creatingPrivateMessage ||
          (composerModel.editingPost &&
            composerModel.post &&
            composerModel.post.post_number === 1))
      );
    },
  });
}

export default {
  name: "lottery-toolbar-button",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.lottery_enabled) {
      withPluginApi("0.8.7", initializeLotteryToolbar);
    }
  },
};
