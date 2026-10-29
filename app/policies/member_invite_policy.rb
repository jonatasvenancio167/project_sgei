class MemberInvitePolicy < ChurchModulePolicy
  MODULE_KEY = "members"
  def index? = user.can_access?(MODULE_KEY, action: "manage") && Access::PermissionQuery.new(user: user).scopes(MODULE_KEY, action: "manage").include?("church")
  def create? = index?
  def destroy? = index? && same_church?
  class Scope < ApplicationPolicy::Scope
    def resolve
      Access::PermissionQuery.new(user: user).scopes("members", action: "manage").include?("church") ? scope.where(church_id: user.church_id) : scope.none
    end
  end
end
