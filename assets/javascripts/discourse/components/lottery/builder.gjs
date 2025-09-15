<template>
    <DModal
      @title={{this.modalTitle}}
      @closeModal={{@closeModal}}
      class="lottery-builder-modal"
    >
      <:body>
        <div class="lottery-builder-container">
          <!-- 修复标签页切换 -->
          <div class="lottery-builder-tabs">
            <button
              type="button"
              class="tab-button {{unless this.showPreview 'active'}}"
              {{on "click" (fn (mut this.showPreview) false)}}
            >
              表单设置
            </button>
            <button
              type="button"
              class="tab-button {{if this.showPreview 'active'}}"
              {{on "click" (fn (mut this.showPreview) true)}}
            >
              实时预览
            </button>
          </div>

          {{#unless this.showPreview}}
            <!-- 表单内容保持不变 -->
            <form class="lottery-builder-form">
              <!-- 之前的表单字段代码不变 -->
              <!-- ... 所有表单字段 ... -->
            </form>
          {{else}}
            <!-- 实时预览 -->
            <div class="lottery-preview-container">
              <LotteryPreview
                @name={{this.previewData.name}}
                @prize={{this.previewData.prize}}
                @prizeImageUrl={{this.previewData.prizeImageUrl}}
                @drawAt={{this.previewData.drawAt}}
                @winnerCount={{this.previewData.winnerCount}}
                @participantThreshold={{this.previewData.participantThreshold}}
                @fallbackStrategy={{this.previewData.fallbackStrategy}}
                @description={{this.previewData.description}}
              />
            </div>
          {{/unless}}
        </div>
      </:body>
      <:footer>
        <DButton
          @action={{this.createOrUpdateLottery}}
          @label={{this.submitButtonLabel}}
          class="btn-primary"
          @disabled={{this.isSubmitDisabled}}
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
