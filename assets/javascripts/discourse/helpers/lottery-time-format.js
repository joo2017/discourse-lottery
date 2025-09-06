import { registerUnbound } from "discourse-common/lib/helpers";

export default registerUnbound("lottery-time-format", function(dateTime) {
  if (!dateTime) return "";
  
  const now = moment();
  const target = moment(dateTime);
  
  if (target.isBefore(now)) {
    return I18n.t("discourse_lottery.time_passed");
  }
  
  const duration = moment.duration(target.diff(now));
  const days = Math.floor(duration.asDays());
  const hours = duration.hours();
  const minutes = duration.minutes();
  
  if (days > 7) {
    return target.format("YYYY-MM-DD HH:mm");
  } else if (days > 0) {
    return I18n.t("discourse_lottery.time_remaining_days", { days, hours });
  } else if (hours > 0) {
    return I18n.t("discourse_lottery.time_remaining_hours", { hours, minutes });
  } else {
    return I18n.t("discourse_lottery.time_remaining_minutes", { minutes });
  }
});
