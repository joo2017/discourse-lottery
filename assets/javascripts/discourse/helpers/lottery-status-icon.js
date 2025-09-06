import { registerUnbound } from "discourse-common/lib/helpers";

export default registerUnbound("lottery-status-icon", function(status) {
  const icons = {
    running: "clock",
    finished: "trophy", 
    cancelled: "times-circle",
    locked: "lock"
  };
  
  return icons[status] || "question";
});
