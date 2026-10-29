class UserPolicy < ChurchModulePolicy
  MODULE_KEY = "members"
  def create? = user.can_access?(MODULE_KEY, action: "manage") && !Access::PermissionQuery.new(user: user).scopes(MODULE_KEY, action: "manage").all? { |s| s == "own" }
  def destroy? = user.can_access?("access", action: "manage") && same_church? && record != user
  def approve? = permitted?("manage", record) && record.status_pending? && same_church?
  def reject? = approve?
  def update_role? = user.can_access?("access", action: "manage") && same_church?
end
