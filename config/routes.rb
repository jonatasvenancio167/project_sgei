Rails.application.routes.draw do
  get "components/index"
  devise_for :users
  resources :notifications
  resources :form_responses
  resources :integrations
  resources :user_notifications
  resources :event_attendees
  resources :events
  resources :memberchips
  resources :departaments do
    member do
      post :add_members
    end
  end
  resources :users
  resources :churches

  # Forms with builder and nested field management
  resources :forms do
    member do
      get  :builder
      get  :statistics
      post :reorder_fields
      patch :toggle_active
    end
    resources :form_fields, only: %i[create update destroy]
  end

  # Public form - no authentication required
  get  "/f/:slug",          to: "public/forms#show",    as: :public_form
  post "/f/:slug",          to: "public/forms#submit",  as: :public_form_submit
  get  "/f/:slug/obrigado", to: "public/forms#success", as: :public_form_success

  get "up" => "rails/health#show", as: :rails_health_check

  get  "overview", to: "overview#index", as: :overview
  get  "painel/calendario", to: "calendario#index", as: :calendario
  get  "painel/eventos", to: "events#index", as: :painel_eventos
  get  "painel/membros", to: "users#index",  as: :painel_membros
  post "painel/membros", to: "users#create", as: :painel_membros_create
  get  "painel/aniversariantes", to: "birthdays#index", as: :painel_aniversariantes
  get    "painel/acolhimento",            to: "welcome_records#index",         as: :painel_acolhimento
  post   "painel/acolhimento",            to: "welcome_records#create",        as: :painel_acolhimento_create
  patch  "painel/acolhimento/:id",        to: "welcome_records#update",        as: :painel_acolhimento_update
  delete "painel/acolhimento/:id",        to: "welcome_records#destroy",       as: :painel_acolhimento_destroy
  patch  "painel/acolhimento/:id/membro", to: "welcome_records#toggle_member", as: :painel_acolhimento_toggle_member
  get    "painel/escalas",          to: "schedules#index",   as: :painel_schedules
  post   "painel/escalas",          to: "schedules#create",  as: :painel_schedules_create
  patch  "painel/escalas/:id",      to: "schedules#update",  as: :painel_schedule_update
  delete "painel/escalas/:id",      to: "schedules#destroy", as: :painel_schedule_destroy
  get    "painel/escalas/:id/:month",             to: "schedules#show",           as: :painel_schedule_month,          constraints: { month: /\d{4}-\d{2}/ }
  post   "painel/escalas/:schedule_id/entradas",   to: "schedule_entries#create",  as: :painel_schedule_entries_create
  delete "painel/escalas/:schedule_id/entradas/:id", to: "schedule_entries#destroy", as: :painel_schedule_entry_destroy

  resources :schedules, only: %i[index create show update destroy]

  get "painel/configuracoes", to: "settings#show", as: :painel_settings

  namespace :settings do
    resource :church, only: :update
    resources :congregations, only: :create do
      member { patch :toggle_status }
    end
    resources :users, only: %i[create destroy] do
      member { patch :toggle_status }
    end
    resource :permissions, only: :update
    resource :notification_settings, only: :update
  end

  root "overview#index"
end
