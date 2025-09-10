import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { cook } from "discourse/lib/text";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class LotteryDescription extends Component {
  @tracked cookedDescription = "";

  get hasDescription() {
    return this.args.description && this.args.description.trim().length > 0;
  }

  @action
  async processDescription(element) {
    if (!this.hasDescription) return;

    try {
      const result = await cook(this.args.description);
      this.cookedDescription = htmlSafe(result.toString());
    } catch (error) {
      console.error("Error cooking description:", error);
      this.cookedDescription = htmlSafe(this.args.description);
    }
  }

  <template>
    {{#if this.hasDescription}}
      <section 
        class="lottery__section lottery-description"
        {{didInsert this.processDescription}}
      >
        {{icon "info-circle"}}
        <div class="description-content">
          {{#if this.cookedDescription}}
            <div class="cooked-description">
              {{this.cookedDescription}}
            </div>
          {{else}}
            <div class="raw-description">
              {{@description}}
            </div>
          {{/if}}
        </div>
      </section>
    {{/if}}
  </template>
}
