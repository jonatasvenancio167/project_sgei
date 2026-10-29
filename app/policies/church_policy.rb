# frozen_string_literal: true

class ChurchPolicy < ApplicationPolicy
  def index?   = user.can_access?("settings", action: "manage")
  def show?    = user.can_access?("settings", action: "manage") && own_church?
  def create?  = false
  def update?  = user.can_access?("settings", action: "manage") && own_church?
  def destroy? = false

  private

  # A user manages their own church and its congregations.
  def own_church?
    record.id == user.church_id || record.parent_church_id == user.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.can_access?("settings", action: "manage")

      scope.where(id: user.church_id).or(scope.where(parent_church_id: user.church_id))
    end
  end
end
