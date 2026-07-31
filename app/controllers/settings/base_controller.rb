module Settings
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      redirect_to root_path, alert: t("settings.errors.admin_only") unless current_user.admin?
    end

    def current_church
      current_user.church
    end
  end
end
