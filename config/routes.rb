Rails.application.routes.draw do
  get "components/index"
  devise_for :users, controllers: { registrations: "registrations" }
  resources :notifications
  resources :form_responses
  resources :integrations
  resources :user_notifications
  resources :event_attendees
  resources :events, except: :destroy do
    resource :approval,     only: :create, controller: "events/approvals"
    resource :rejection,    only: :create, controller: "events/rejections"
    resource :cancellation, only: :create, controller: "events/cancellations"
    resource :resubmission, only: :create, controller: "events/resubmissions"
  end
  resources :memberchips
  resources :departaments do
    resources :members, only: :create, controller: "departaments/members"
  end
  resources :users do
    resource :approval,  only: :create, controller: "members/approvals"
    resource :rejection, only: :create, controller: "members/rejections"
  end
  resources :churches, except: :destroy

  # Forms with builder and nested field management
  resources :forms do
    resource :builder,        only: :show,   controller: "forms/builders"
    resource :statistics,     only: :show,   controller: "forms/statistics"
    resource :field_ordering, only: :update, controller: "forms/field_orderings"
    resource :activation,     only: :update, controller: "forms/activations"
    resources :form_fields, only: %i[create update destroy]
  end

  # Public form - no authentication required
  get  "/f/:slug",          to: "public/forms#show",    as: :public_form
  post "/f/:slug",          to: "public/forms#submit",  as: :public_form_submit
  get  "/f/:slug/obrigado", to: "public/forms#success", as: :public_form_success

  # Public Convite de Membro form - no authentication required
  get  "/i/:token",          to: "public/member_invites#show",    as: :public_member_invite
  post "/i/:token",          to: "public/member_invites#create",  as: :public_member_invite_submit
  get  "/i/:token/obrigado", to: "public/member_invites#success", as: :public_member_invite_success

  get "up" => "rails/health#show", as: :rails_health_check

  get  "overview", to: "overview#index", as: :overview
  get  "panel/calendar", to: "calendar#index", as: :panel_calendar
  get  "panel/events", to: "events#index", as: :panel_events
  get  "panel/members", to: "users#index",  as: :panel_members
  post "panel/members", to: "users#create", as: :panel_members_create
  get    "panel/members/invites",     to: "members/invites#index",   as: :panel_member_invites
  post   "panel/members/invites",     to: "members/invites#create",  as: :panel_member_invites_create
  delete "panel/members/invites/:id", to: "members/invites#destroy", as: :panel_member_invite_destroy
  get  "panel/birthdays", to: "birthdays#index", as: :panel_birthdays
  get    "panel/welcome",            to: "welcome_records#index",         as: :panel_welcome
  post   "panel/welcome",            to: "welcome_records#create",        as: :panel_welcome_create
  patch  "panel/welcome/:id",        to: "welcome_records#update",        as: :panel_welcome_update
  delete "panel/welcome/:id",        to: "welcome_records#destroy",       as: :panel_welcome_destroy
  patch  "panel/welcome/:welcome_record_id/conversion", to: "welcome_records/conversions#update", as: :panel_welcome_conversion
  get    "panel/schedules",          to: "schedules#index",   as: :panel_schedules
  post   "panel/schedules",          to: "schedules#create",  as: :panel_schedules_create
  patch  "panel/schedules/:id",      to: "schedules#update",  as: :panel_schedule_update
  delete "panel/schedules/:id",      to: "schedules#destroy", as: :panel_schedule_destroy
  get    "panel/schedules/:id/:month",           to: "schedules#show",           as: :panel_schedule_month,          constraints: { month: /\d{4}-\d{2}/ }
  post   "panel/schedules/:schedule_id/entries",   to: "schedule_entries#create",  as: :panel_schedule_entries_create
  delete "panel/schedules/:schedule_id/entries/:id", to: "schedule_entries#destroy", as: :panel_schedule_entry_destroy

  resources :schedules, only: %i[index create show update destroy]

  get "panel/settings", to: "settings#show", as: :panel_settings

  namespace :settings do
    resource :church, only: :update
    resources :congregations, only: :create do
      resource :status, only: :update, controller: "congregations/statuses"
    end
    resources :users, only: %i[create update destroy] do
      resource :status, only: :update, controller: "users/statuses"
    end
    resource :permissions, only: :update
    resource :notification_settings, only: :update
  end

  root "overview#index"
end
