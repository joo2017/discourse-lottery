export function formatTimeRemaining(drawTime) {
  if (!drawTime) return null;
  
  const now = moment();
  const target = moment(drawTime);
  
  if (target.isBefore(now)) {
    return I18n.t("discourse_lottery.time_passed");
  }
  
  const duration = moment.duration(target.diff(now));
  const days = Math.floor(duration.asDays());
  const hours = duration.hours();
  const minutes = duration.minutes();
  
  if (days > 0) {
    return I18n.t("discourse_lottery.time_remaining_days", { days, hours });
  } else if (hours > 0) {
    return I18n.t("discourse_lottery.time_remaining_hours", { hours, minutes });
  } else {
    return I18n.t("discourse_lottery.time_remaining_minutes", { minutes });
  }
}

export function validateLotteryForm(formData, globalMinParticipants = 1) {
  const errors = {};
  
  // 基础验证
  if (!formData.activityName?.trim()) {
    errors.activityName = I18n.t("discourse_lottery.validation.activity_name_required");
  }
  
  if (!formData.prizeDescription?.trim()) {
    errors.prizeDescription = I18n.t("discourse_lottery.validation.prize_description_required");
  }
  
  if (!formData.drawTime) {
    errors.drawTime = I18n.t("discourse_lottery.validation.draw_time_required");
  } else if (moment(formData.drawTime).isBefore(moment())) {
    errors.drawTime = I18n.t("discourse_lottery.validation.draw_time_past");
  }
  
  if (!formData.winnerCount || formData.winnerCount < 1) {
    errors.winnerCount = I18n.t("discourse_lottery.validation.winner_count_invalid");
  }
  
  if (!formData.minParticipants || formData.minParticipants < globalMinParticipants) {
    errors.minParticipants = I18n.t("discourse_lottery.validation.min_participants_too_low", {
      min: globalMinParticipants
    });
  }
  
  // 指定楼层验证
  if (formData.fixedFloors?.trim()) {
    const floors = formData.fixedFloors
      .split(",")
      .map(f => parseInt(f.trim()))
      .filter(f => !isNaN(f) && f > 0);
    
    if (floors.length === 0) {
      errors.fixedFloors = I18n.t("discourse_lottery.validation.fixed_floors_invalid");
    }
  }
  
  return errors;
}

export function parseLotteryMarkdown(content) {
  // 解析抽奖表单标记
  const lotteryRegex = /\[lottery-form\]([\s\S]*?)\[\/lottery-form\]/g;
  const matches = lotteryRegex.exec(content);
  
  if (!matches) return null;
  
  const formContent = matches[1];
  const lines = formContent.split('\n').filter(line => line.trim());
  
  const data = {};
  lines.forEach(line => {
    const [key, ...valueParts] = line.split('：');
    if (key && valueParts.length > 0) {
      const value = valueParts.join('：').trim();
      data[key.trim()] = value;
    }
  });
  
  return data;
}
