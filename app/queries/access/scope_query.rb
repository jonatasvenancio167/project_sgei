module Access
  class ScopeQuery
    def initialize(user:, scope:, module_key:, action: "read", church: user.church)
      @user, @scope, @module_key, @action, @church = user, scope.all, module_key, action, church
    end

    def call
      grants = PermissionQuery.new(user: @user, church: @church).scopes(@module_key, action: @action)
      grants.reduce(@scope.none) { |result, grant| result.or(relation_for(grant)) }
    end

    private

    def relation_for(grant)
      hierarchy = grant == "hierarchy" && @action == "read" && %w[members departments forms birthdays].include?(@module_key)
      church_ids = hierarchy ? @church.accessible_church_ids : [ @church.id ]
      relation = tenant_relation(church_ids)
      case grant
      when "church", "hierarchy" then relation
      when "own" then own_relation(relation)
      when "audience" then audience_relation(relation)
      when "team", "led" then team_relation(relation, grant)
      else @scope.none
      end
    end

    def tenant_relation(ids)
      case @scope.klass.name
      when "User"
        @scope.where(id: ChurchMembership.where(church_id: ids, active: true).select(:user_id))
      when "FormAnswer", "FormResponse"
        @scope.where(form_id: Form.where(church_id: ids).select(:id))
      when "EventAttendee"
        @scope.where(event_id: Event.where(church_id: ids).select(:id))
      when "Memberchip"
        @scope.where(departament_id: Departament.where(church_id: ids).select(:id))
      else
        @scope.where(church_id: ids)
      end
    end

    def own_relation(relation)
      case @scope.klass.name
      when "User" then relation.where(id: @user.id)
      when "Schedule"
        relation.where(id: ScheduleEntry.where(id: @user.schedule_assignments.select(:schedule_entry_id)).select(:schedule_id))
      when "FormResponse", "EventAttendee" then relation.where(user_id: @user.id)
      when "FormAnswer" then relation.where(form_response_id: FormResponse.where(user_id: @user.id).select(:id))
      when "Form"
        @action == "read" ? relation.where(id: FormResponse.where(user_id: @user.id).select(:form_id)) : relation.none
      else relation.none
      end
    end

    def audience_relation(relation)
      return relation.where(user_id: @user.id) if @scope.klass == EventAttendee
      return relation.none unless @scope.klass == Event
      relation.where(status: %i[approved archived]).where(visibility: %i[public_event member_only])
    end

    def team_relation(relation, grant)
      links = @user.memberchips.joins(:departament).where(departaments: { church_id: @church.id })
      links = links.where(role: :leader) if grant == "led"
      departments = links.select(:departament_id)
      case @scope.klass.name
      when "Departament" then relation.where(id: departments)
      when "User" then relation.where(id: Memberchip.where(departament_id: departments).select(:user_id))
      when "Schedule", "Event" then relation.where(departament_id: departments)
      when "Memberchip" then relation.where(departament_id: departments)
      else relation.none
      end
    end
  end
end
