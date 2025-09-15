import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (!siteSettings.lottery_enabled) {
    return;
  }

  // 只使用一种方式注册按钮
  api.addComposerToolbarPopupMenuOption({
    action: (toolbarEvent) => {
      const modal = api.container.lookup("service:modal");
      
      modal.show("lottery-builder", {
        model: {
          toolbarEvent: toolbarEvent,
          editMode: false
        }
      });
    },
    icon: "gift",
    label: "lottery.builder.attach"
  });
});
