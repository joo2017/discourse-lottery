import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class LotteryPrize extends Component {
  @tracked imageLoaded = false;
  @tracked imageError = false;

  get hasPrizeImage() {
    return this.args.lottery?.prize_image_url && 
           this.args.lottery.prize_image_url.trim().length > 0;
  }

  get prizeImageUrl() {
    return this.args.lottery?.prize_image_url;
  }

  get prizeImageAlt() {
    return i18n("lottery.ui.prize_image_alt", {
      name: this.args.lottery?.name || "抽奖"
    });
  }

  @action
  onImageLoad() {
    this.imageLoaded = true;
    this.imageError = false;
  }

  @action
  onImageError() {
    this.imageError = true;
    this.imageLoaded = false;
  }

  @action
  openImageModal() {
    if (!this.hasPrizeImage || this.imageError) return;

    // 创建一个简单的图片预览模态
    const modal = document.createElement('div');
    modal.className = 'lottery-image-modal';
    modal.innerHTML = `
      <div class="modal-backdrop" onclick="this.parentElement.remove()">
        <div class="modal-content" onclick="event.stopPropagation()">
          <img src="${this.prizeImageUrl}" alt="${this.prizeImageAlt}" />
          <button class="close-btn" onclick="this.closest('.lottery-image-modal').remove()">
            <i class="d-icon d-icon-times"></i>
          </button>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    document.body.classList.add('modal-open');
    
    // 自动清理
    modal.addEventListener('click', (e) => {
      if (e.target === modal || e.target.classList.contains('modal-backdrop')) {
        document.body.classList.remove('modal-open');
        modal.remove();
      }
    });
  }

  <template>
    {{#if this.hasPrizeImage}}
      <section class="lottery__section lottery-prize-image">
        {{icon "image"}}
        <div class="prize-image-container">
          {{#if this.imageError}}
            <div class="image-error">
              {{icon "exclamation-triangle"}}
              <span>奖品图片加载失败</span>
            </div>
          {{else}}
            <div class="prize-image-wrapper">
              {{#unless this.imageLoaded}}
                <div class="image-loading">
                  {{icon "spinner" class="fa-spin"}}
                  <span>加载中...</span>
                </div>
              {{/unless}}
              
              <img
                src={{this.prizeImageUrl}}
                alt={{this.prizeImageAlt}}
                class="prize-image {{if this.imageLoaded 'loaded'}}"
                {{on "load" this.onImageLoad}}
                {{on "error" this.onImageError}}
                {{on "click" this.openImageModal}}
                title="点击查看大图"
              />
              
              {{#if this.imageLoaded}}
                <div class="image-overlay">
                  <button
                    type="button"
                    class="expand-image-btn"
                    {{on "click" this.openImageModal}}
                    title="点击查看大图"
                  >
                    {{icon "expand"}}
                  </button>
                </div>
              {{/if}}
            </div>
          {{/if}}
        </div>
      </section>
    {{/if}}
  </template>
}
