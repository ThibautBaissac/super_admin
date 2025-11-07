SuperAdmin::Engine.routes.draw do
  root "dashboard#index"

  resources :exports, only: %i[index show create destroy], param: :token do
    member do
      get :download
    end
  end

  get "associations/search", to: "associations#search", as: :association_search

  resources :audit_logs, only: [ :index ]

  get ":resource", to: "resources#index", as: :resources
  post ":resource/bulk", to: "resources#bulk", as: :bulk_action
  get ":resource/new", to: "resources#new", as: :new_resource
  post ":resource", to: "resources#create"
  get ":resource/:id", to: "resources#show", as: :resource
  get ":resource/:id/edit", to: "resources#edit", as: :edit_resource
  patch ":resource/:id", to: "resources#update"
  delete ":resource/:id", to: "resources#destroy"
end
