export default {
  name: "lottery-setup",
  
  initialize(app) {
    // 注册抽奖相关的自定义字段类型
    app.register("lottery-field:text", "input");
    app.register("lottery-field:number", "input"); 
    app.register("lottery-field:datetime", "input");
    app.register("lottery-field:select", "select");
    app.register("lottery-field:textarea", "textarea");
  }
};
