class DepartamentPolicy < ChurchModulePolicy
  MODULE_KEY = "departments"
  def create? = user.can_access?(MODULE_KEY, action: "manage") && Access::PermissionQuery.new(user: user).scopes(MODULE_KEY, action: "manage").include?("church")
  def destroy? = same_church? && user.can_access?(MODULE_KEY, action: "manage", record: record)
  def add_members? = same_church? && user.can_access?(MODULE_KEY, action: "manage", record: record)
end
