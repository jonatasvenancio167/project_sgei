module Audit
  # Central place for writing audit trail entries. Failures are logged and
  # swallowed so auditing never breaks the main flow.
  class RecordService < BaseService
    def initialize(church:, user:, module_key:, action:, detail: nil)
      @church = church
      @user = user
      @module_key = module_key
      @action = action
      @detail = detail
    end

    def call
      audit_log = church.audit_logs.create!(user: user, module_key: module_key, action: action, detail: detail)
      Success(audit_log)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Audit::RecordService] #{e.message}")
      Failure(:invalid)
    end

    private

    attr_reader :church, :user, :module_key, :action, :detail
  end
end
