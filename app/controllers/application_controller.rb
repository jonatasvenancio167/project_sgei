class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  # Brings the Success()/Failure() constants into scope so controllers can
  # pattern-match on Service results (see docs/design_patters.md §4.4).
  include Dry::Monads[:result]

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: t("errors.not_authorized") }
      format.json { render json: { error: t("errors.forbidden") }, status: :forbidden }
      format.any  { head :forbidden }
    end
  end

  def not_found
    respond_to do |format|
      format.html { render file: "public/404.html", status: :not_found, layout: false }
      format.json { render json: { error: t("errors.not_found") }, status: :not_found }
      format.any  { head :not_found }
    end
  end
end
