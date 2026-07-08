class SettingsController < Settings::BaseController
  SECTIONS = SettingsHelper::SECTIONS.map { |section| section[:key] }.freeze
  AUDIT_PAGE_SIZES = [10, 25, 50].freeze

  # GET /painel/configuracoes
  def show
    @church = current_church
    @section = SECTIONS.include?(params[:section]) ? params[:section] : "church"
    send("load_#{@section}")
  end

  private

  def load_church; end

  def load_integrations; end

  def load_congregations
    @congregations = @church.congregations.includes(:address).order(:name)
  end

  def load_users
    @users = SettingsUserQuery.new(
      church: @church,
      filters: params.permit(:q, :role, :status)
    ).call
  end

  def load_permissions
    @permissions = @church.role_permissions.index_by { |p| [p.role, p.module_key] }
  end

  def load_notifications
    persisted = @church.notification_settings.index_by(&:event_key)
    @notification_settings = NotificationSetting::EVENTS.keys.index_with do |event_key|
      persisted[event_key] || @church.notification_settings.build(event_key: event_key)
    end
  end

  def load_audit
    logs = AuditLogQuery.new(
      church: @church,
      filters: params.permit(:module_key, :start_date, :end_date)
    ).call

    per = AUDIT_PAGE_SIZES.include?(params[:per].to_i) ? params[:per].to_i : 10
    @pagy, @audit_logs = pagy(logs, limit: per)
  end
end
