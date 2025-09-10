import { apiInitializer } from "discourse/lib/api";
import LotteryBuilder from "discourse/plugins/discourse-lottery/discourse/components/modal/lottery-builder";

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (siteSettings.lottery_enabled) {
    const modal = api.container.lookup("service:modal");

    api.addComposerToolbarPopupMenuOption({
      action: (toolbarEvent) => {
        modal.show(LotteryBuilder, { 
          model: { toolbarEvent } 
        });
      },
      group: "insertions",
      icon: "gift",
      label: "lottery.builder.attach",
      condition: (composer) => {
        const composerModel = composer.model;
        // Only allow on new topics for simplicity, as per blueprint.
        return (
          composerModel &&
          !composerModel.replyingToTopic &&
          (composerModel.topicFirstPost || composerModel.creatingPrivateMessage)
        );
      },
    });
  }
});
