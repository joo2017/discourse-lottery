import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

export default class LotteryToggle extends Component {
  @service site;
  @service currentUser;
  @tracked isLotteryEnabled = false;
  @tracked lotteryData = null;

  get shouldShowLotteryOption() {
    if (!this.site.lottery_settings?.enabled) return false;
    if (!this.currentUser) return false;
    
    // 检查当前分类是否允许抽奖
    const allowedCategories = this.site.lottery_settings.allowed_categories;
    if (allowedCategories.length > 0) {
      const currentCategoryId = this.args.outletArgs.model.categoryId;
      return allowedCategories.includes(currentCategoryId?.toString());
    }
    
    return true;
  }

  @action
  toggleLotteryForm() {
    this.isLotteryEnabled = !this.isLotteryEnabled;
    
    if (!this.isLotteryEnabled) {
      this.lotteryData = null;
      // 清除编辑器中的抽奖内容
      this.clearLotteryFromComposer();
    }
  }

  @action
  handleLotterySubmit(lotteryData) {
    this.lotteryData = lotteryData;
    this.insertLotteryIntoComposer(lotteryData);
  }

  insertLotteryIntoComposer(lotteryData) {
    // 将抽奖数据插入到编辑器中
    const lotteryMarkdown = this.generateLotteryMarkdown(lotteryData);
    const composer = this.args.outletArgs.model;
    
    if (composer.reply) {
      composer.set('reply', composer.reply + '\n\n' + lotteryMarkdown);
    } else {
      composer.set('reply', lotteryMarkdown);
    }
  }

  clearLotteryFromComposer() {
    const composer = this.args.outletArgs.model;
    if (composer.reply) {
      // 移除抽奖标记内容
      const cleanedReply = composer.reply.replace(/\[lottery-data\][\s\S]*?\[\/lottery-data\]/g, '');
      composer.set('reply', cleanedReply.trim());
    }
  }

  generateLotteryMarkdown(data) {
    return `[lottery-data]
{
  "name": "${data.activityName}",
  "prize_description": "${data.prizeDescription}",
  "prize_image_url": "${data.prizeImageUrl || ''}",
  "draw_time": "${data.drawTime}",
  "winner_count": ${data.winnerCount},
  "fixed_floors": "${data.fixedFloors || ''}",
  "min_participants": ${data.minParticipants},
  "backup_strategy": "${data.backupStrategy}",
  "additional_notes": "${data.additionalNotes || ''}",
  "draw_method": "${data.drawMethod}",
  "effective_winner_count": ${data.effectiveWinnerCount}
}
[/lottery-data]`;
  }
}
