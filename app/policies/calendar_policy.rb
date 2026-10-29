class CalendarPolicy < ApplicationPolicy
  def index? = user.can_access?("calendar")
end
