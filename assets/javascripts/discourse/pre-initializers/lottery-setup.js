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

// 使用示例和最佳实践
export const LotteryUsageExamples = {
  // 在模板中使用抽奖组件
  basicUsage: `
    {{#if topic.lottery_data}}
      <LotteryStatusCard @lottery={{topic.lottery_data}} />
    {{/if}}
  `,
  
  // 在编辑器中集成抽奖表单
  composerIntegration: `
    {{#if shouldShowLotteryOption}}
      <LotteryToggle @composer={{model}} />
    {{/if}}
  `,
  
  // 管理员面板集成
  adminIntegration: `
    <div class="admin-lottery-panel">
      <LotteryAdminPanel />
    </div>
  `,
  
  // 自定义抽奖显示
  customDisplay: `
    <div class="custom-lottery-display">
      {{#each activeLotteries as |lottery|}}
        <div class="lottery-summary">
          <h4>{{lottery.name}}</h4>
          <span class="time-remaining">
            {{lottery-time-format lottery.draw_time}}
          </span>
          <span class="status">
            {{d-icon (lottery-status-icon lottery.status)}}
            {{i18n (concat "discourse_lottery.status." lottery.status)}}
          </span>
        </div>
      {{/each}}
    </div>
  `
};

// 开发调试工具
export const LotteryDevTools = {
  // 生成测试数据
  generateTestLottery() {
    return {
      id: Date.now(),
      name: "测试抽奖",
      prize_description: "测试奖品",
      draw_time: moment().add(1, "day").toISOString(),
      winner_count: 3,
      min_participants: 10,
      status: "running",
      current_participants: 15
    };
  },
  
  // 模拟参与抽奖
  simulateParticipation(lotteryId, userCount = 10) {
    const participants = [];
    for (let i = 1; i <= userCount; i++) {
      participants.push({
        id: i,
        username: `testuser${i}`,
        floor_number: i + 1,
        participated_at: moment().subtract(i, "hours").toISOString()
      });
    }
    return participants;
  },
  
  // 验证抽奖数据
  validateLotteryData(data) {
    const errors = [];
    
    if (!data.name) errors.push("活动名称不能为空");
    if (!data.prize_description) errors.push("奖品说明不能为空");
    if (!data.draw_time) errors.push("开奖时间不能为空");
    if (!data.winner_count || data.winner_count < 1) errors.push("获奖人数必须大于0");
    if (!data.min_participants || data.min_participants < 1) errors.push("参与门槛必须大于0");
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }
};
