# frozen_string_literal: true

# Default deny: subclasses must explicitly grant each action.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false

  private

  def admin?     = user.admin?
  def leader?    = user.leader?
  def pastor?    = user.pastor?
  def co_pastor? = user.co_pastor?

  # Tenant isolation: the record must belong to the user's church.
  def same_church?
    record_church_id == user.church_id
  end

  # Hierarchy-aware read: the record must belong to a church the user's
  # church can see (itself, or — for the Sede — one of its congregations).
  # Only use this for modules whose visibility matrix grants the Sede
  # read access across congregations (Membros, Departamentos, Formulários,
  # Aniversariantes). Writes stay scoped by `same_church?`.
  def within_hierarchy?
    user.allowed_church_ids.include?(record_church_id)
  end

  def record_church_id
    return user.church_id if record.is_a?(User) && record.church_memberships.where(church_id: user.church_id).exists?
    return record.form.church_id if record.respond_to?(:form) && record.form
    return record.event.church_id if record.respond_to?(:event) && record.event
    return record.departament.church_id if record.is_a?(Memberchip)
    record.respond_to?(:church_id) ? record.church_id : nil
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    attr_reader :user, :scope
  end
end
