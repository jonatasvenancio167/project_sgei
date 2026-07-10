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

  def admin?  = user.admin?
  def leader? = user.leader?

  # Tenant isolation: the record must belong to the user's church.
  def same_church?
    record_church_id == user.church_id
  end

  def record_church_id
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
