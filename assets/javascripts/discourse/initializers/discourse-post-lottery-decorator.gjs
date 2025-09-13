import { withPluginApi } from "discourse/lib/plugin-api";
import DiscoursePostLotteryLottery from "discourse/plugins/discourse-lottery/discourse/models/discourse-post-lottery-lottery";
import DiscoursePostLottery from "discourse/plugins/discourse-lottery/discourse/components/discourse-post-lottery";

function initializeDiscoursePostLotteryDecorator(api) {
  api.decorateCookedElement(
    (cooked, helper) => {
      if (cooked.classList.contains("d-editor-preview")) {
        return; // 预览模式处理
      }

      if (helper) {
        const post = helper.getModel();

        if (!post?.lottery) {
          return;
        }

        const lotteryNode = cooked.querySelector(".discourse-post-lottery");

        if (!lotteryNode) {
          return;
        }

        const wrapper = document.createElement("div");
        lotteryNode.before(wrapper);

        const lottery = DiscoursePostLotteryLottery.create(post.lottery);

        helper.renderGlimmer(
          wrapper,
          <template><DiscoursePostLottery @lottery={{lottery}} /></template>
        );
      }
    },
    {
      id: "discourse-post-lottery-decorator",
    }
  );
}

export default {
  name: "discourse-post-lottery-decorator",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.lottery_enabled) {
      withPluginApi("0.8.7", initializeDiscoursePostLotteryDecorator);
    }
  },
};
