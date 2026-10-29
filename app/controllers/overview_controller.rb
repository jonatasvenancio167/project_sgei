class OverviewController < ApplicationController
  def index
    @user = current_user

    # Events in the next 7 days (scoped to the user's church)
    @upcoming_events = policy_scope(Event)
                            .where(start_date: Time.current..7.days.from_now)
                            .includes(:departament)
                            .order(start_date: :asc)

    # Active Forms
    @active_forms = policy_scope(Form).active.includes(:departament, event: :departament)
    
    # Stats logic
    if @user.admin?
      attendees_count = policy_scope(EventAttendee).count
      @stats = [
        { label: "Eventos este mês", value: policy_scope(Event).where(start_date: Time.current.beginning_of_month..Time.current.end_of_month).count.to_s, icon: "calendar-days", hint: "+4 vs. mês passado" },
        { label: "Inscrições abertas", value: policy_scope(Form).active.count.to_s, icon: "clipboard-list", hint: "#{attendees_count} inscritos no total" },
        { label: "Membros ativos", value: policy_scope(User).status_active.count.to_s, icon: "users", hint: "#{policy_scope(Departament).count} departamentos" },
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
