module Members
  # Gestão de links de "Convite de Membro" (docs/Ekklesia/telas/membros.md §7.8)
  class InvitesController < ApplicationController
    before_action :set_invite, only: :destroy

    # GET /panel/members/invites
    def index
      authorize MemberInvite
      @invites = policy_scope(MemberInvite).order(created_at: :desc)
    end

    # POST /panel/members/invites
    def create
      authorize MemberInvite
      result = Members::CreateInviteService.call(
        church: current_user.church, created_by: current_user, params: invite_params
      )

      case result
      in Success(invite)
        redirect_to panel_member_invites_path, notice: t(".success", link: public_member_invite_url(invite.token))
      in Failure(invite)
        redirect_to panel_member_invites_path, alert: invite.errors.full_messages.to_sentence
      end
    end

    # DELETE /panel/members/invites/:id
    def destroy
      @invite.deactivate!
      Audit::RecordService.call(
        church: @invite.church, user: current_user,
        module_key: "members", action: "Desativou convite de membro", detail: @invite.note
      )
      redirect_to panel_member_invites_path, notice: t(".success"), status: :see_other
    end

    private

    def set_invite
      @invite = policy_scope(MemberInvite).find(params[:id])
      authorize @invite
    end

    def invite_params
      params.require(:member_invite).permit(:expires_in, :max_uses, :note)
    end
  end
end
