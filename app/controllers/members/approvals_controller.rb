module Members
  # POST /users/:user_id/approval
  class ApprovalsController < ApplicationController
    def create
      user = policy_scope(User).find(params[:user_id])
      authorize user, :approve?

      result = Members::ApproveRegistrationService.call(user: user, performed_by: current_user)

      case result
      in Success(user)
        redirect_to panel_members_path, notice: t(".success", name: user.name)
      in Failure(user)
        redirect_to panel_members_path, alert: user.errors.full_messages.to_sentence
      end
    end
  end
end
