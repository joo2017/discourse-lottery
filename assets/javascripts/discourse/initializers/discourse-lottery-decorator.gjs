import { apiInitializer } from "discourse/lib/api";
import Lottery from "discourse/plugins/discourse-lottery/discourse/components/lottery";

function initializeLotteryDecorator(api) {
  api.decorateCookedElement(
    (cooked, helper) => {
      const lotteryNodes = cooked.querySelectorAll(".discourse-lottery");
      if (!lotteryNodes.length) {
        return;
      }

      lotteryNodes.forEach((lotteryNode) => {
        // 避免重复处理
        if (lotteryNode.hasAttribute('data-lottery-processed')) {
          return;
        }
        
        const post = helper?.getModel();
        let lotteryData;

        if (post?.lottery) {
          // 帖子模式：使用真实数据
          lotteryData = post.lottery;
        } else {
          // 预览模式：从BBCode属性中提取数据
          lotteryData = extractLotteryDataFromNode(lotteryNode);
        }

        if (!lotteryData) {
          // 如果没有数据，显示占位符
          lotteryNode.innerHTML = '<div class="lottery-placeholder">抽奖预览加载中...</div>';
          return;
        }

        // 标记已处理，避免重复处理
        lotteryNode.setAttribute('data-lottery-processed', 'true');
        
        // 安全地替换内容
        try {
          // 清空现有内容
          lotteryNode.innerHTML = '';
          
          // 创建wrapper
          const wrapper = document.createElement("div");
          wrapper.className = "lottery-component-wrapper";
          lotteryNode.appendChild(wrapper);

          // 渲染组件
          helper.renderGlimmer(
            wrapper,
            <template><Lottery @lottery={{lotteryData}} /></template>
          );
        } catch (error) {
          console.error("Lottery decorator error:", error);
          lotteryNode.innerHTML = '<div class="lottery-error">抽奖组件加载失败</div>';
        }
      });
    },
    {
      id: "discourse-lottery-decorator",
      onlyStream: true,
      afterAdopt: true,
    }
  );
}

// 从BBCode节点中提取抽奖数据的辅助函数
function extractLotteryDataFromNode(node) {
  try {
    // 从data属性中提取信息
    const name = node.getAttribute('data-lottery-name') || '预览抽奖';
    const prize = node.getAttribute('data-lottery-prize') || '预览奖品';
    const drawAt = node.getAttribute('data-lottery-draw-at') || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const winnerCount = parseInt(node.getAttribute('data-lottery-winner-count')) || 1;
    const participantThreshold = parseInt(node.getAttribute('data-lottery-participant-threshold')) || 5;
    const fallbackStrategy = node.getAttribute('data-lottery-fallback-strategy') || 'continue';
    const description = node.getAttribute('data-lottery-description') || '';
    const prizeImageUrl = node.getAttribute('data-lottery-prize-image-url') || '';

    return {
      id: 'preview',
      name: name,
      prize: prize,
      prize_image_url: prizeImageUrl,
      status: 'running',
      draw_at: drawAt,
      winner_count: winnerCount,
      participant_threshold: participantThreshold,
      fallback_strategy: fallbackStrategy,
      description: description,
      post: {
        id: 'preview',
        topic_id: 'preview'
      }
    };
  } catch (error) {
    console.error("Error extracting lottery data:", error);
    return null;
  }
}

export default apiInitializer("1.15.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  
  if (siteSettings.lottery_enabled) {
    initializeLotteryDecorator(api);
  }
});
