# frozen_string_literal: true

class IntegrationPolicy < ApplicationPolicy
  def index?   = admin?
  def show?    = admin? && same_church?
  def create?  = admin?
  def update?  = admin? && same_church?
  def destroy? = admin? && same_church?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.where(church_id: user.church_id) : scope.none
    end
  end
end
