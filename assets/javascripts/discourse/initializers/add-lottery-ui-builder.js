import { apiInitializer } from "discourse/lib/api";
import LotteryBuilder from "discourse/plugins/discourse-lottery/discourse/components/modal/lottery-builder";

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (!siteSettings.lottery_enabled) {
    return;
  }

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
      
      // 只允许在新主题中创建抽奖，符合设计蓝图
      return (
        composerModel &&
        !composerModel.replyingToTopic &&
        (composerModel.topicFirstPost || composerModel.creatingPrivateMessage) &&
        composerModel.canEditTitle
      );
    },
  });

  // 注册快捷键支持
  api.addKeyboardShortcut("ctrl+shift+l", () => {
    const composer = api.container.lookup("controller:composer");
    if (composer && composer.model && !composer.model.replyingToTopic) {
      modal.show(LotteryBuilder, { 
        model: { toolbarEvent: { addText: (text) => composer.model.appendText(text) } } 
      });
    }
  }, {
    global: false,
    category: "composer",
    description: "lottery.builder.keyboard_shortcut",
  });

  // 为工具栏按钮添加提示信息
  api.addToolbarPopupMenuOptionsCallback((composer) => {
    if (!siteSettings.lottery_enabled) return [];
    
    const composerModel = composer.model;
    const canCreateLottery = composerModel && 
                           !composerModel.replyingToTopic &&
                           (composerModel.topicFirstPost || composerModel.creatingPrivateMessage) &&
                           composerModel.canEditTitle;

    if (canCreateLottery) {
      return [{
        action: (toolbarEvent) => {
          modal.show(LotteryBuilder, { 
            model: { toolbarEvent } 
          });
        },
        group: "insertions",
        icon: "gift",
        label: "lottery.builder.attach",
        title: "lottery.builder.attach_title"
      }];
    }
    
    return [];
  });
});
