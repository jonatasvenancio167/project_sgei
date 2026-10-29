class EventPolicy < ChurchModulePolicy
  MODULE_KEY = "events"
  def create? = user.can_access?(MODULE_KEY, action: "manage")
  def update? = same_church? && permitted?("manage", record)
  def destroy? = false
  def approve? = update? && record.pending_approval?
  def reject? = approve?
  def cancel? = update? && record.approved?
  def resubmit? = update? && record.rejected? && record.created_by_id == user.id
end
