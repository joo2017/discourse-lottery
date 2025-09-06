import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { later } from "@ember/runloop";

export default class LotteryForm extends Component {
  @service site;
  @service currentUser;
  @tracked formData = {
    activityName: "",
    prizeDescription: "",
    prizeImageUrl: "",
    drawTime: "",
    winnerCount: 1,
    fixedFloors: "",
    minParticipants: 5,
    backupStrategy: "continue",
    additionalNotes: ""
  };
  @tracked validationErrors = {};
  @tracked isSubmitting = false;
  @tracked showPreview = false;

  constructor() {
    super(...arguments);
    // 设置默认参与门槛为全局最小值
    if (this.site.lottery_settings?.min_participants_global) {
      this.formData.minParticipants = this.site.lottery_settings.min_participants_global;
    }
  }

  get globalMinParticipants() {
    return this.site.lottery_settings?.min_participants_global || 1;
  }

  get isFormValid() {
    this.validateForm();
    return Object.keys(this.validationErrors).length === 0;
  }

  get drawMethod() {
    return this.formData.fixedFloors.trim() ? "fixed" : "random";
  }

  get effectiveWinnerCount() {
    if (this.drawMethod === "fixed" && this.formData.fixedFloors.trim()) {
      const floors = this.parseFixedFloors();
      return floors.length;
    }
    return this.formData.winnerCount;
  }

  parseFixedFloors() {
    if (!this.formData.fixedFloors.trim()) return [];
    
    return this.formData.fixedFloors
      .split(",")
      .map(floor => parseInt(floor.trim()))
      .filter(floor => !isNaN(floor) && floor > 0);
  }

  validateForm() {
    const errors = {};

    // 活动名称验证
    if (!this.formData.activityName.trim()) {
      errors.activityName = I18n.t("discourse_lottery.validation.activity_name_required");
    } else if (this.formData.activityName.length > 100) {
      errors.activityName = I18n.t("discourse_lottery.validation.activity_name_too_long");
    }

    // 奖品说明验证
    if (!this.formData.prizeDescription.trim()) {
      errors.prizeDescription = I18n.t("discourse_lottery.validation.prize_description_required");
    }

    // 开奖时间验证
    if (!this.formData.drawTime) {
      errors.drawTime = I18n.t("discourse_lottery.validation.draw_time_required");
    } else if (moment(this.formData.drawTime).isBefore(moment())) {
      errors.drawTime = I18n.t("discourse_lottery.validation.draw_time_past");
    }

    // 获奖人数验证
    if (!this.formData.winnerCount || this.formData.winnerCount < 1) {
      errors.winnerCount = I18n.t("discourse_lottery.validation.winner_count_invalid");
    }

    // 参与门槛验证
    if (!this.formData.minParticipants || this.formData.minParticipants < 1) {
      errors.minParticipants = I18n.t("discourse_lottery.validation.min_participants_required");
    } else if (this.formData.minParticipants < this.globalMinParticipants) {
      errors.minParticipants = I18n.t("discourse_lottery.validation.min_participants_too_low", {
        min: this.globalMinParticipants
      });
    }

    // 指定楼层验证（如果填写了）
    if (this.formData.fixedFloors.trim()) {
      const floors = this.parseFixedFloors();
      if (floors.length === 0) {
        errors.fixedFloors = I18n.t("discourse_lottery.validation.fixed_floors_invalid");
      }
    }

    this.validationErrors = errors;
  }

  @action
  updateField(field, value) {
    this.formData[field] = value;
    
    // 实时验证特定字段
    if (field === "minParticipants") {
      this.validateMinParticipants(value);
    } else if (field === "drawTime") {
      this.validateDrawTime(value);
    } else if (field === "fixedFloors") {
      this.validateFixedFloors(value);
    }
  }

  @action
  validateMinParticipants(value) {
    const numValue = parseInt(value);
    if (numValue < this.globalMinParticipants) {
      this.validationErrors.minParticipants = I18n.t(
        "discourse_lottery.validation.min_participants_too_low",
        { min: this.globalMinParticipants }
      );
    } else {
      delete this.validationErrors.minParticipants;
    }
    // 触发响应式更新
    this.validationErrors = { ...this.validationErrors };
  }

  @action
  validateDrawTime(value) {
    if (value && moment(value).isBefore(moment())) {
      this.validationErrors.drawTime = I18n.t("discourse_lottery.validation.draw_time_past");
    } else {
      delete this.validationErrors.drawTime;
    }
    this.validationErrors = { ...this.validationErrors };
  }

  @action
  validateFixedFloors(value) {
    if (value.trim()) {
      const floors = this.parseFixedFloors();
      if (floors.length === 0) {
        this.validationErrors.fixedFloors = I18n.t("discourse_lottery.validation.fixed_floors_invalid");
      } else {
        delete this.validationErrors.fixedFloors;
      }
    } else {
      delete this.validationErrors.fixedFloors;
    }
    this.validationErrors = { ...this.validationErrors };
  }

  @action
  togglePreview() {
    this.showPreview = !this.showPreview;
  }

  @action
  async submitForm() {
    if (!this.isFormValid) return;

    this.isSubmitting = true;
    
    try {
      // 构建提交数据
      const submitData = {
        ...this.formData,
        drawMethod: this.drawMethod,
        effectiveWinnerCount: this.effectiveWinnerCount
      };

      // 这里模拟提交过程
      await new Promise(resolve => later(resolve, 2000));
      
      // 调用父组件回调
      if (this.args.onSubmit) {
        this.args.onSubmit(submitData);
      }

      // 显示成功消息
      this.appEvents.trigger("modal-body:flash", {
        text: I18n.t("discourse_lottery.messages.creation_success"),
        messageClass: "success"
      });

    } catch (error) {
      // 显示错误消息
      this.appEvents.trigger("modal-body:flash", {
        text: I18n.t("discourse_lottery.messages.creation_failed", { error: error.message }),
        messageClass: "error"
      });
    } finally {
      this.isSubmitting = false;
    }
  }

  @action
  uploadPrizeImage(file) {
    // 这里处理图片上传逻辑
    // 暂时模拟上传成功
    const fakeUrl = URL.createObjectURL(file);
    this.updateField("prizeImageUrl", fakeUrl);
  }
}
