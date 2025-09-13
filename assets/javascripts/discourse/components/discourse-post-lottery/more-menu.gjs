import Component from "@glimmer/component";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "float-kit/components/d-menu";

export default class MoreMenu extends Component {
  @service currentUser;

  <template>
    {{#if @canActOnLottery}}
      <DMenu
        @identifier="discourse-post-lottery-more-menu"
        @triggerClass="more-dropdown"
        @icon="ellipsis"
      >
        <:content>
          <DropdownMenu as |dropdown|>
            <dropdown.item class="edit-lottery">
              <DButton
                @icon="pencil"
                @label="编辑抽奖"
                class="btn-transparent"
              />
            </dropdown.item>

            <dropdown.item class="cancel-lottery">
              <DButton
                @icon="times"
                @label="取消抽奖"
                class="btn-transparent btn-danger"
              />
            </dropdown.item>
          </DropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
