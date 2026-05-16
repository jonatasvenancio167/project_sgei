class OverviewController < ApplicationController
  def index
    @user = current_user
    
    # Events in the next 7 days
    @upcoming_events = Event.where(start_date: Time.current..7.days.from_now)
                            .includes(:departament)
                            .order(start_date: :asc)

    # Filter events based on user permissions
    unless @user.admin?
      @upcoming_events = @upcoming_events.where(departament_id: @user.departament_ids + [nil])
    end

    # Active Forms
    @active_forms = Form.where(active: true).includes(:event, event: :departament)
    
    unless @user.admin?
      # Forms are associated with events, which are associated with departments
      @active_forms = @active_forms.joins(:event).where(events: { departament_id: @user.departament_ids + [nil] })
    end

    # Stats logic
    if @user.admin?
      @stats = [
        { label: "Eventos este mês", value: Event.where(start_date: Time.current.beginning_of_month..Time.current.end_of_month).count.to_s, icon: "calendar-days", hint: "+4 vs. mês passado" },
        { label: "Inscrições abertas", value: Form.where(active: true).count.to_s, icon: "clipboard-list", hint: "#{EventAttendee.count} inscritos no total" },
        { label: "Membros ativos", value: User.status_active.count.to_s, icon: "users", hint: "#{Departament.count} departamentos" },
        { label: "Engajamento", value: "87%", icon: "trending-up", hint: "Notificações abertas" }
      ]
    else
      @stats = [
        { label: "Eventos do depto.", value: @upcoming_events.where(departament_id: @user.departament_ids).count.to_s, icon: "calendar-days", hint: @user.primary_department_name },
        { label: "Eventos gerais", value: @upcoming_events.where(departament_id: nil).count.to_s, icon: "calendar-days", hint: "Igreja" },
        { label: "Inscrições visíveis", value: @active_forms.count.to_s, icon: "clipboard-list", hint: "Para o seu perfil" },
        { label: "Perfil", value: @user.role_label.split(" ").first, icon: "users", hint: @user.primary_department_name }
      ]
    end
  end
end
