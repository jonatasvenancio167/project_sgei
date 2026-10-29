class FormAnswerPolicy < ChurchModulePolicy
  MODULE_KEY = "forms"
  def create? = record.form_response && record.form_response.user_id == user.id && user.can_access?("forms", action: "manage", record: record.form_response)
end
