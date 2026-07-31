# frozen_string_literal: true

class FormPolicy < ChurchModulePolicy
  MODULE_KEY = "forms"

  # Sede sees forms across all of its congregations; managing a form
  # stays restricted to the user's own church.
  def show? = module_allowed? && within_hierarchy?

  def builder?        = update?
  def statistics?      = show?
  def reorder_fields?  = update?
  def toggle_active?   = update?

  class Scope < ChurchModulePolicy::Scope
    def resolve
      scope.where(church_id: user.allowed_church_ids)
    end
  end
end
