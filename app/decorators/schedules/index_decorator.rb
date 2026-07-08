module Schedules
  class IndexDecorator
    attr_reader :schedules, :user, :view_context

    def initialize(schedules, user, view_context)
      @schedules = schedules
      @user = user
      @view_context = view_context
    end

    def empty?
      schedules.empty?
    end

    def decorated_schedules
      schedules.map { |schedule| ScheduleDecorator.new(schedule, view_context) }
    end

    def department_options
      scope = user.admin? ? user.church.departaments : user.departaments
      scope.order(:name)
    end

    def color_choices
      Schedule::COLOR_CHOICES
    end

    def current_month
      Date.current.strftime("%Y-%m")
    end
  end
end
