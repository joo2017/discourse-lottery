import { withPluginApi } from "discourse/lib/plugin-api";
import DiscoursePostLotteryLottery from "discourse/plugins/discourse-lottery/discourse/models/discourse-post-lottery-lottery";
import PostLotteryBuilder from "../components/modal/post-lottery-builder";

function initializeLotteryBuilder(api) {
  const currentUser = api.getCurrentUser();
  const modal = api.container.lookup("service:modal");

  api.addComposerToolbarPopupMenuOption({
    action: (toolbarEvent) => {
      const lottery = DiscoursePostLotteryLottery.create({
        status: "public",
        draw_time: moment().add(1, 'day'),
        winner_count: 1,
        min_participants: 1,
        draw_method: "random",
        backup_strategy: "continue"
      });

      modal.show(PostLotteryBuilder, {
        model: { lottery, toolbarEvent },
      });
    },
    group: "insertions",
    icon: "gift", // 使用礼物图标
    label: "discourse_lottery.builder_modal.attach",
    condition: (composer) => {
      if (!currentUser || !currentUser.can_create_discourse_lottery) {
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
  name: "add-post-lottery-builder",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.discourse_lottery_enabled) {
      withPluginApi("0.8.7", initializeLotteryBuilder);
    }
  },
};
