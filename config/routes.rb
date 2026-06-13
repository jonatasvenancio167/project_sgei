Rails.application.routes.draw do
  get "components/index"
  devise_for :users
  resources :notifications
  resources :form_responses
  resources :integrations
  resources :user_notifications
  resources :form_answers
  resources :form_fields
  resources :forms
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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get  "overview", to: "overview#index", as: :overview
  get  "painel/calendario", to: "calendario#index", as: :calendario
  get  "painel/eventos", to: "events#index", as: :painel_eventos
  get  "painel/membros", to: "users#index",  as: :painel_membros
  post "painel/membros", to: "users#create", as: :painel_membros_create


  
  # Defines the root path route ("/")
  root "overview#index"
end
