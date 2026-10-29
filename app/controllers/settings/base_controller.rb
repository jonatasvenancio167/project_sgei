module Settings
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      permission = if controller_name == "settings"
        %w[permissions users].include?(params[:section]) ? "access" : "settings"
      else
        (controller_path.start_with?("settings/users") || %w[permissions access_profiles].include?(controller_name)) ? "access" : "settings"
      end
      raise Pundit::NotAuthorizedError unless current_user.can_access?(permission, action: "manage")
    end

    def current_church
      current_user.church
    end
  end
end
