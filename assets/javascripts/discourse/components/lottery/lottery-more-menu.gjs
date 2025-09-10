import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import EmberObject, { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import concatClass from "discourse/helpers/concat-class";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { exportEntity } from "discourse/lib/export-csv";
import { i18n } from "discourse-i18n";
import DMenu from "float-kit/components/d-menu";
import LotteryBuilder from "../modal/lottery-builder";

export default class LotteryMoreMenu extends Component {
  @service currentUser;
  @service dialog;
  @service modal;
  @service router;
  @service siteSettings;
  @service store;

  @tracked isSavingLottery = false;

  get isExpiredOrFinished() {
    return (
      this.args.lottery?.status === "finished" ||
      this.args.lottery?.status === "cancelled"
    );
  }

  get canEditLottery() {
    return (
      this.args.canActOnLottery &&
      this.args.lottery?.status === "running" &&
      !this.isExpiredOrFinished
    );
  }

  get canCancelLottery() {
    return (
      this.args.canActOnLottery &&
      this.args.lottery?.status === "running" &&
      !this.isExpiredOrFinished
    );
  }

  get canExportLottery() {
    return this.args.canActOnLottery;
  }

  get canSendPmToCreator() {
    return (
      this.currentUser &&
      this.args.lottery?.post?.user_id &&
      this.currentUser.id !== this.args.lottery.post.user_id
    );
  }

  get creatorUsername() {
    return this.args.lottery?.post?.username;
  }

  @action
  registerMenuApi(api) {
    this.menuApi = api;
  }

  @action
  sendPMToCreator() {
    this.menuApi?.close();

    if (this.args.lottery?.post?.user_id && this.args.composePrivateMessage) {
      const creator = EmberObject.create({
        id: this.args.lottery.post.user_id,
        username: this.creatorUsername,
      });
      const post = EmberObject.create(this.args.lottery.post);

      this.args.composePrivateMessage(creator, post);
    }
  }

  @action
  exportLottery() {
    this.menuApi?.close();

    if (this.args.lottery?.id) {
      exportEntity("lottery", {
        name: "lottery",
        id: this.args.lottery.id,
      });
    }
  }

  @action
  async editLottery() {
    this.menuApi?.close();

    this.modal.show(LotteryBuilder, {
      model: {
        lottery: this.args.lottery,
        editMode: true,
      },
    });
  }

  @action
  async cancelLottery() {
    this.menuApi?.close();

    this.dialog.yesNoConfirm({
      message: i18n("lottery.more_menu.confirm_cancel"),
      didConfirm: async () => {
        this.isSavingLottery = true;

        try {
          await ajax(`/lotteries/${this.args.lottery.id}/cancel`, {
            type: "PUT",
          });

          if (this.args.onLotteryUpdated) {
            this.args.onLotteryUpdated();
          }
        } catch (error) {
          popupAjaxError(error);
        } finally {
          this.isSavingLottery = false;
        }
      },
    });
  }

  @action
  showParticipants() {
    this.menuApi?.close();

    this.modal.show("lottery-participants-modal", {
      model: {
        lottery: this.args.lottery,
        title: i18n("lottery.participants.title", {
          name: this.args.lottery?.name || "抽奖",
        }),
      },
    });
  }

  @action
  showWinners() {
    this.menuApi?.close();

    this.modal.show("lottery-winners-modal", {
      model: {
        lottery: this.args.lottery,
        winners: this.args.lottery?.winners || [],
        title: i18n("lottery.winners.title", {
          name: this.args.lottery?.name || "抽奖",
        }),
      },
    });
  }

  @action
  copyLotteryLink() {
    this.menuApi?.close();

    if (this.args.lottery?.post?.url) {
      const fullUrl = window.location.origin + this.args.lottery.post.url;
      navigator.clipboard
        .writeText(fullUrl)
        .then(() => {
          // 可以添加一个 toast 提示
          console.log("链接已复制到剪贴板");
        })
        .catch((err) => {
          console.error("复制链接失败:", err);
        });
    }
  }

  @action
  refreshLottery() {
    this.menuApi?.close();

    if (this.args.onLotteryUpdated) {
      this.args.onLotteryUpdated();
    }
  }

  @action
  viewLotteryHistory() {
    this.menuApi?.close();

    // 这里可以实现查看抽奖历史的功能
    // 暂时跳转到话题页面
    if (this.args.lottery?.post?.topic_id) {
      this.router.transitionTo("topic", this.args.lottery.post.topic_id);
    }
  }

  <template>
    {{#if this.args.canActOnLottery}}
      <DMenu
        @identifier="discourse-lottery-more-menu"
        @triggerClass={{concatClass
          "more-dropdown"
          (if this.isSavingLottery "--saving")
        }}
        @icon="ellipsis"
        @onRegisterApi={{this.registerMenuApi}}
      >
        <:content>
          <DropdownMenu as |dropdown|>
            {{#unless this.isExpiredOrFinished}}
              <dropdown.item class="refresh-lottery">
                <DButton
                  @icon="sync-alt"
                  @label="lottery.more_menu.refresh"
                  @action={{this.refreshLottery}}
                  class="btn-transparent"
                />
              </dropdown.item>

              <dropdown.item class="copy-lottery-link">
                <DButton
                  @icon="link"
                  @label="lottery.more_menu.copy_link"
                  @action={{this.copyLotteryLink}}
                  class="btn-transparent"
                />
              </dropdown.item>
            {{/unless}}

            {{#if this.canSendPmToCreator}}
              <dropdown.item class="send-pm-to-creator">
                <DButton
                  @icon="envelope"
                  class="btn-transparent"
                  @translatedLabel={{i18n
                    "lottery.more_menu.send_pm_to_creator"
                    (hash username=this.creatorUsername)
                  }}
                  @action={{this.sendPMToCreator}}
                />
              </dropdown.item>
            {{/if}}

            <dropdown.divider />

            <dropdown.item class="show-participants">
              <DButton
                @icon="users"
                class="btn-transparent"
                @label="lottery.more_menu.show_participants"
                @action={{this.showParticipants}}
              />
            </dropdown.item>

            {{#if this.args.lottery.winners}}
              <dropdown.item class="show-winners">
                <DButton
                  @icon="trophy"
                  class="btn-transparent"
                  @label="lottery.more_menu.show_winners"
                  @action={{this.showWinners}}
                />
              </dropdown.item>
            {{/if}}

            <dropdown.item class="view-lottery-history">
              <DButton
                @icon="history"
                class="btn-transparent"
                @label="lottery.more_menu.view_history"
                @action={{this.viewLotteryHistory}}
              />
            </dropdown.item>

            {{#if this.canExportLottery}}
              <dropdown.divider />

              <dropdown.item class="export-lottery">
                <DButton
                  @icon="file-csv"
                  class="btn-transparent"
                  @label="lottery.more_menu.export_lottery"
                  @action={{this.exportLottery}}
                />
              </dropdown.item>
            {{/if}}

            {{#if this.canEditLottery}}
              <dropdown.divider />

              <dropdown.item class="edit-lottery">
                <DButton
                  @icon="pencil"
                  class="btn-transparent"
                  @label="lottery.more_menu.edit_lottery"
                  @action={{this.editLottery}}
                />
              </dropdown.item>
            {{/if}}

            {{#if this.canCancelLottery}}
              <dropdown.item class="cancel-lottery">
                <DButton
                  @icon="xmark"
                  @label="lottery.more_menu.cancel_lottery"
                  @action={{this.cancelLottery}}
                  @disabled={{this.isSavingLottery}}
                  class="btn-transparent btn-danger"
                />
              </dropdown.item>
            {{/if}}
          </DropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
