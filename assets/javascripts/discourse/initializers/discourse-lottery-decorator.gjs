import { apiInitializer } from "discourse/lib/api";
import LotteryIndex from "discourse/plugins/discourse-lottery/discourse/components/lottery/index";

function initializeLotteryDecorator(api) {
  api.decorateCooked(
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
            <template><LotteryIndex @lottery={{lotteryData}} /></template>
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
    const specifiedWinners = node.getAttribute('data-lottery-specified-winners') || '';

    return {
      id: 'preview',
      name: name,
      prize: prize,
      prize_image_url: prizeImageUrl,
      status: 'running',
      draw_at: drawAt,
      winner_count: winnerCount,
      participant_threshold: participantThreshold,
      participant_count: Math.floor(Math.random() * (participantThreshold + 5)), // 预览模式随机参与人数
      fallback_strategy: fallbackStrategy,
      description: description,
      specified_winners: specifiedWinners,
      winners: [], // 预览模式没有获奖者
      post: {
        id: 'preview',
        topic_id: 'preview',
        user_id: null,
        username: 'preview_user',
        url: '#preview'
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
    
    // 监听消息总线更新
    api.onPageChange(() => {
      const messageBus = api.container.lookup("service:message-bus");
      
      // 订阅全局抽奖更新
      messageBus.subscribe("/lottery/global", (data) => {
        // 处理全局抽奖状态更新
        if (data.type === "status_change" && data.lottery_id) {
          const lotteryElements = document.querySelectorAll(`[data-lottery-id="${data.lottery_id}"]`);
          lotteryElements.forEach(element => {
            // 触发重新渲染
            element.removeAttribute('data-lottery-processed');
            const event = new CustomEvent('lottery-update', { detail: data });
            element.dispatchEvent(event);
          });
        }
      });
    });

    // 添加抽奖相关的CSS类到body
    api.onPageChange((url, title) => {
      const hasLottery = document.querySelector('.discourse-lottery');
      if (hasLottery) {
        document.body.classList.add('has-lottery-content');
      } else {
        document.body.classList.remove('has-lottery-content');
      }
    });

    // 为抽奖添加主题列表自定义字段支持
    api.addPreloadedTopicListCustomField("lottery_draw_at");
    
    // 在主题列表中显示抽奖图标
    api.addTopicTitleDecorator((topicModel, node) => {
      if (topicModel.lottery_draw_at) {
        const lotteryIcon = document.createElement('span');
        lotteryIcon.className = 'topic-lottery-icon';
        lotteryIcon.innerHTML = '<svg class="fa d-icon d-icon-gift svg-icon svg-string" xmlns="http://www.w3.org/2000/svg"><use href="#gift"></use></svg>';
        lotteryIcon.title = '包含抽奖活动';
        node.insertBefore(lotteryIcon, node.firstChild);
      }
    });
  }
});
