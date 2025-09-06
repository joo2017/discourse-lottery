import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-lottery-init",

  initialize() {
    withPluginApi("0.8.31", api => {
      // 1. 扩展编辑器，添加抽奖创建按钮
      api.addToolbarPopupMenuOptionsCallback(() => {
        return {
          action: "insertLotteryTemplate",
          icon: "dice",
          label: "discourse_lottery.actions.create_lottery",
          condition: () => {
            const site = api.container.lookup("service:site");
            return site.lottery_settings?.enabled;
          }
        };
      });

      // 2. 扩展编辑器控制器，添加插入抽奖模板功能
      api.modifyClass("controller:composer", {
        actions: {
          insertLotteryTemplate() {
            const lotteryTemplate = this.generateLotteryTemplate();
            this.appEvents.trigger("composer:insert-text", lotteryTemplate);
          }
        },

        generateLotteryTemplate() {
          return `[lottery-form]
活动名称：
奖品说明：
奖品图片：
开奖时间：
获奖人数：
指定中奖楼层：
参与门槛：
后备策略：
补充说明：
[/lottery-form]`;
        }
      });

      // 3. 装饰帖子内容，渲染抽奖组件
      api.decorateCooked($elem => {
        const $lotteryContainers = $elem.find(".lottery-container, [data-lottery-id]");
        $lotteryContainers.each((index, element) => {
          this.renderLotteryComponent(element);
        });
      });

      // 4. 注册自定义BBCode或标记处理
      api.addDiscourseMarkdownRule("lottery-form", {
        tag: "lottery-form",
        replace: function(state, tagInfo, content) {
          const token = state.push("lottery_form", "div", 0);
          token.attrSet("class", "lottery-form-container");
          token.content = content;
          return true;
        }
      });
    });
  },

  renderLotteryComponent(element) {
    // 这里会渲染抽奖组件，暂时用占位符
    const $element = $(element);
    if (!$element.hasClass("lottery-rendered")) {
      $element.addClass("lottery-rendered");
      // 实际组件渲染逻辑
    }
  }
};
