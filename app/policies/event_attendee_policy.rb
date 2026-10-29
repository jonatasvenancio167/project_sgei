class EventAttendeePolicy < ChurchModulePolicy
  MODULE_KEY = "events"
  def create?
    return false unless record.is_a?(EventAttendee) && record.event
    (record.user_id == user.id && user.can_access?("events", record: record.event)) || permitted?("manage", record)
  end
  def update? = record.user_id == user.id && show?
  def destroy? = update? || permitted?("manage", record)
end
