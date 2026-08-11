module Public
  # Formulário público de auto-cadastro via Convite de Membro
  # (docs/Ekklesia/telas/membros.md §7.5-7.7). No authentication required.
  class MemberInvitesController < ApplicationController
    skip_before_action :authenticate_user!
    layout "public"

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    # GET /i/:token
    def show
      @invite = MemberInvite.usable.find_by!(token: params[:token])
      @user = User.new
    end

    # POST /i/:token
    def create
      @invite = MemberInvite.usable.find_by!(token: params[:token])

      result = Members::PublicRegistrationService.call(invite: @invite, params: registration_params)

      case result
      in Success(_)
        redirect_to public_member_invite_success_path(params[:token])
      in Failure(User => user)
        @user = user
        render :show, status: :unprocessable_entity
      in Failure(:unusable)
        render_not_found
      end
    end

    # GET /i/:token/obrigado
    def success
      # The invite may already be exhausted/expired by now — only the
      # church name is needed here, so we look it up without `.usable`.
      @invite = MemberInvite.find_by!(token: params[:token])
    end

    private

    def render_not_found
      render "public/member_invites/not_found", status: :not_found
    end

    def registration_params
      params.require(:user).permit(:name, :phone, :email, :birth_date)
    end
  end
end
