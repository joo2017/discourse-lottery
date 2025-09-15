import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (!siteSettings.lottery_enabled) {
    return;
  }

  // 使用正确的现代 API
  api.onToolbarCreate((toolbar) => {
    if (toolbar.context !== "composer") {
      return;
    }

    toolbar.addButton({
      id: "lottery_ui_builder",
      group: "extras",
      icon: "gift", 
      label: "lottery.builder.attach",
      shortcut: "Ctrl+Shift+L",
      action: (toolbarEvent) => {
        const modal = api.container.lookup("service:modal");
        
        // 动态导入组件
        import("discourse/plugins/discourse-lottery/discourse/components/lottery/builder")
          .then((module) => {
            const LotteryBuilder = module.default;
            modal.show(LotteryBuilder, {
              model: {
                toolbarEvent: toolbarEvent,
                editMode: false
              }
            });
          })
          .catch((error) => {
            console.error("Failed to load LotteryBuilder component:", error);
            
            // 备用方案：直接插入BBCode
            const now = new Date();
            const tomorrow = new Date(now.getTime() + 24*60*60*1000);
            const drawAtString = tomorrow.toISOString().slice(0,16);
            
            const basicBBCode = `[lottery name="抽奖活动" prize="奖品描述" drawAt="${drawAtString}" winnerCount="1" participantThreshold="5" fallbackStrategy="continue"]\n[/lottery]`;
            toolbarEvent.addText(basicBBCode);
          });
      }
    });
  });
});
