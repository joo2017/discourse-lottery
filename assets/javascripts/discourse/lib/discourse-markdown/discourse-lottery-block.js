const rule = {
  tag: "lottery",

  wrap(token, info) {
    // A lottery must have a drawAt time to be considered valid for rendering.
    if (!info.attrs.drawAt) {
      return false;
    }

    // 创建包含抽奖数据的占位符div
    const attrs = [
      ["class", "discourse-lottery"],
      ["data-lottery-name", info.attrs.name || ""],
      ["data-lottery-prize", info.attrs.prize || ""],
      ["data-lottery-draw-at", info.attrs.drawAt || ""],
      ["data-lottery-winner-count", info.attrs.winnerCount || "1"],
      ["data-lottery-participant-threshold", info.attrs.participantThreshold || "5"],
      ["data-lottery-fallback-strategy", info.attrs.fallbackStrategy || "continue"],
      ["data-lottery-description", info.attrs.description || ""],
      ["data-lottery-prize-image-url", info.attrs.prizeImageUrl || ""]
    ];

    token.attrs = attrs;
    
    // 添加简单的预览内容，避免复杂的HTML
    token.content = `
      <div class="lottery-preview-wrapper">
        <div class="lottery-preview-header">
          <strong>${info.attrs.name || "抽奖活动"}</strong>
          <span class="lottery-preview-status">进行中</span>
        </div>
        <div class="lottery-preview-content">
          <div><strong>奖品：</strong>${info.attrs.prize || ""}</div>
          <div><strong>开奖时间：</strong>${info.attrs.drawAt || ""}</div>
          <div><strong>获奖人数：</strong>${info.attrs.winnerCount || "1"}</div>
          <div><strong>参与门槛：</strong>${info.attrs.participantThreshold || "5"}</div>
        </div>
      </div>
    `;
    
    return true;
  },
};

export function setup(helper) {
  // 更安全的白名单设置
  helper.allowList([
    "div.discourse-lottery",
    "div.lottery-preview-wrapper",
    "div.lottery-preview-header", 
    "div.lottery-preview-content",
    "span.lottery-preview-status",
    "strong"
  ]);

  // 允许data属性
  helper.allowList({
    custom(tag, name, value) {
      if (tag === 'div' && name.match(/^data-lottery-/)) {
        return true;
      }
      return false;
    }
  });

  helper.registerOptions((opts, siteSettings) => {
    opts.features.discourse_lottery = !!siteSettings.lottery_enabled;
  });

  helper.registerPlugin((md) => {
    if (md.options.discourse.features.discourse_lottery) {
      md.block.bbcode.ruler.push("discourse-lottery", rule);
    }
  });
}
