class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Você não tem permissão para acessar esta página." }
      format.json { render json: { error: "não autorizado" }, status: :forbidden }
      format.any  { head :forbidden }
    end
  end
end
