import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { applyLocalDates } from "discourse/lib/local-dates";
import { cook } from "discourse/lib/text";

export default class LotteryDates extends Component {
  @service siteSettings;

  @tracked htmlDates = "";

  get drawAtTime() {
    if (!this.args.lottery?.draw_at) return null;
    return moment(this.args.lottery.draw_at);
  }

  get drawAtFormat() {
    if (!this.drawAtTime) return "";
    return this._buildFormat(this.drawAtTime, {
      includeYear: !this.isSameYear(this.drawAtTime),
      includeTime: true,
    });
  }

  _buildFormat(date, { includeYear, includeTime }) {
    const formatParts = ["ddd, MMM D"];
    if (includeYear) {
      formatParts.push("YYYY");
    }

    const dateString = formatParts.join(", ");
    const timeString = includeTime ? " LT" : "";

    return `\u0022${dateString}${timeString}\u0022`;
  }

  isSameYear(date1, date2) {
    return date1.isSame(date2 || moment(), "year");
  }

  buildDateBBCode() {
    if (!this.drawAtTime) return "";
    
    const bbcode = {
      date: this.drawAtTime.format("YYYY-MM-DD"),
      time: this.drawAtTime.format("HH:mm"),
      format: this.drawAtFormat,
      timezone: "UTC",
    };

    const content = Object.entries(bbcode)
      .map(([key, value]) => `${key}=${value}`)
      .join(" ");

    return `[${content}]`;
  }

  @action
  async computeDates(element) {
    if (!this.drawAtTime) {
      this.htmlDates = htmlSafe("开奖时间未设置");
      return;
    }

    if (this.siteSettings.discourse_local_dates_enabled) {
      try {
        const result = await cook(this.buildDateBBCode());
        this.htmlDates = htmlSafe(result.toString());

        next(() => {
          if (this.isDestroying || this.isDestroyed) {
            return;
          }

          const localDateElements = element.querySelectorAll(
            `[data-post-id="${this.args.lottery?.id}"] .discourse-local-date`
          );
          
          if (localDateElements.length > 0) {
            applyLocalDates(localDateElements, this.siteSettings);
          }
        });
      } catch (error) {
        console.error("Error cooking dates:", error);
        this.htmlDates = htmlSafe(this.drawAtTime.format(this.drawAtFormat));
      }
    } else {
      const formattedDate = this.drawAtTime.format(this.drawAtFormat);
      this.htmlDates = htmlSafe(formattedDate);
    }
  }

  get isOverdue() {
    if (!this.drawAtTime) return false;
    return this.drawAtTime.isBefore(moment()) && this.args.lottery?.status === "running";
  }

  get timeRemaining() {
    if (!this.drawAtTime || this.args.lottery?.status !== "running") return null;
    
    const now = moment();
    const drawTime = this.drawAtTime;
    
    if (drawTime.isBefore(now)) {
      return "已过期";
    }
    
    const duration = moment.duration(drawTime.diff(now));
    const days = Math.floor(duration.asDays());
    const hours = duration.hours();
    const minutes = duration.minutes();
    
    if (days > 0) {
      return `还剩 ${days} 天 ${hours} 小时`;
    } else if (hours > 0) {
      return `还剩 ${hours} 小时 ${minutes} 分钟`;
    } else {
      return `还剩 ${minutes} 分钟`;
    }
  }

  <template>
    <section 
      class="lottery__section lottery-dates" 
      {{didInsert this.computeDates}}
    >
      {{icon "clock"}}
      <div class="dates-content">
        <div class="draw-time">
          {{this.htmlDates}}
        </div>
        {{#if this.timeRemaining}}
          <div class="time-remaining {{if this.isOverdue 'overdue'}}">
            {{this.timeRemaining}}
          </div>
        {{/if}}
      </div>
    </section>
  </template>
}
