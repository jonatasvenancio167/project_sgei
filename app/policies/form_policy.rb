class FormPolicy < ChurchModulePolicy
  MODULE_KEY = "forms"
  def create? = Access::PermissionQuery.new(user: user).scopes(MODULE_KEY, action: "manage").include?("church") && (record.is_a?(Class) || record.church_id == user.church_id)
  def builder? = update?
  def statistics? = update?
  def reorder_fields? = update?
  def toggle_active? = update?
end
