class ScheduleQuery
  def initialize(user:)
    @user = user
  end

  def call
    scope = Schedule.includes(:departament, :schedule_columns)
                    .where(church_id: user.church_id)
                    .order(:name)

    apply_permission_filter(scope)
  end

  private

  attr_reader :user

  def apply_permission_filter(scope)
    return scope if user.admin?

    scope.where(departament_id: user.departament_ids)
  end
end
