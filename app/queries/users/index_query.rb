module Users
  # Builds the filtered scope for the members listing (panel/members):
  # leader-scoping, free-text search, role filter and department filter.
  class IndexQuery
    def initialize(scope:, user:, departaments:, params:)
      @scope = scope
      @user = user
      @departaments = departaments
      @params = params
    end

    def call
      scope = @scope
      scope = filter_by_term(scope)
      scope = filter_by_role(scope)
      filter_by_departament(scope)
    end

    private

    attr_reader :user, :departaments, :params

    def filter_by_term(scope)
      term = params[:q].to_s.strip
      return scope if term.blank?

      like = "%#{term}%"
      scope.where("name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", like, like, like)
    end

    def filter_by_role(scope)
      return scope unless params[:role].present? && params[:role] != "todos"

      scope.where(id: ProfileAssignment.joins(:access_profile, :church_membership).where(access_profiles: { key: params[:role] }, church_memberships: { church_id: user.church_id }).select("church_memberships.user_id"))
    end

    def filter_by_departament(scope)
      case params[:dept]
      when "sem"
        # A leader's scope is already restricted to their departments, so
        # "sem departamento" can never match anyone there.
        scope.left_outer_joins(:memberchips).where(memberchips: { id: nil })
      when "todos", "", nil
        scope
      else
        dept = departaments.find_by(id: params[:dept])
        dept ? scope.joins(:memberchips).where(memberchips: { departament_id: dept.id }) : scope
      end
    end
  end
end
