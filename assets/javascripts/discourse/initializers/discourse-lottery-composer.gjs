import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (!siteSettings.lottery_enabled) {
    return;
  }

  // 确保只执行一次
  if (window.lotteryToolbarInitialized) {
    return;
  }
  window.lotteryToolbarInitialized = true;

  // 在 composer 上添加自定义操作
  api.modifyClass("component:composer-editor", {
    pluginId: "discourse-lottery",

    actions: {
      showLotteryBuilder() {
        const modal = this.modal || this.container.lookup("service:modal");
        
        import("discourse/plugins/discourse-lottery/discourse/components/lottery/builder")
          .then((module) => {
            const LotteryBuilder = module.default;
            modal.show(LotteryBuilder, {
              model: {
                toolbarEvent: this,
                editMode: false
              }
            });
          })
          .catch((error) => {
            console.error("Failed to load LotteryBuilder component:", error);
            
            const now = new Date();
            const tomorrow = new Date(now.getTime() + 24*60*60*1000);
            const drawAtString = tomorrow.toISOString().slice(0,16);
            
            const basicBBCode = `[lottery name="抽奖活动" prize="奖品描述" drawAt="${drawAtString}" winnerCount="1" participantThreshold="5" fallbackStrategy="continue"]\n[/lottery]`;
            this.addText(basicBBCode);
          });
      }
    }
  });

  // 添加工具栏按钮到弹出菜单
  api.addComposerToolbarPopupMenuOption({
    action: "showLotteryBuilder",
    icon: "gift",
    label: "lottery.builder.attach"
  });
});
