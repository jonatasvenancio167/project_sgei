class ChurchContextsController < ApplicationController
  def update
    membership = current_user.church_memberships.find_by!(church_id: params[:church_id], active: true, access_enabled: true)
    session[:current_church_id] = membership.church_id
    redirect_to root_path, status: :see_other
  end
end
