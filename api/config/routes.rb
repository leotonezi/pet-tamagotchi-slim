Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, skip: :all

  namespace :api do
    namespace :v1 do
      scope :auth do
        post   "sign_up",  to: "auth#sign_up"
        post   "sign_in",  to: "auth#sign_in"
        delete "sign_out", to: "auth#sign_out"
        get    "me",       to: "auth#me"
      end

      resources :items, only: [:index]

      get  "inventory",      to: "inventory#show"
      post "inventory/buy",  to: "inventory#buy"
      post "inventory/use",  to: "inventory#use"

      resources :pets, only: %i[index show create destroy] do
        member do
          post :feed
          post :walk
          post :bathe
          post :sleep
          post :play
          post :check_status
        end
      end
    end
  end
end
