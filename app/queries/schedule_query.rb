class ScheduleQuery
  def initialize(user:)
    @user = user
  end

  def call
    scope = Schedule.includes(:departament, :schedule_columns)
                    .where(church_id: user.church_id)
                    .order(:name)

    Access::ScopeQuery.new(user: user, scope: scope, module_key: "schedules").call
  end

  private

  attr_reader :user
end
