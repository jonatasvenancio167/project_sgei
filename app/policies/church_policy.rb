# frozen_string_literal: true

class ChurchPolicy < ApplicationPolicy
  def index?   = admin?
  def show?    = admin? && own_church?
  def create?  = false
  def update?  = admin? && own_church?
  def destroy? = false

  private

  # A user manages their own church and its congregations.
  def own_church?
    record.id == user.church_id || record.parent_church_id == user.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.admin?

      scope.where(id: user.church_id).or(scope.where(parent_church_id: user.church_id))
    end
  end
end
