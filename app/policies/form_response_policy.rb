# frozen_string_literal: true

class FormResponsePolicy < ChurchModulePolicy
  MODULE_KEY = "forms"

  def show? = module_allowed? && within_hierarchy?

  private

  def record_church_id
    record.form&.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:form).where(forms: { church_id: user.allowed_church_ids })
    end
  end
end
