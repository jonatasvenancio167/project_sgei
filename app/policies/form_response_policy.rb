# frozen_string_literal: true

class FormResponsePolicy < ChurchModulePolicy
  MODULE_KEY = "forms"

  private

  def record_church_id
    record.form&.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:form).where(forms: { church_id: user.church_id })
    end
  end
end
