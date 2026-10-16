Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "csrf", to: "csrf#show"
      post "registration", to: "registrations#create"
      resource :session, only: %i[create destroy], controller: "sessions"
      get "me", to: "me#show"
      resources :stores, only: %i[index show create update] do
        resources :memberships, only: %i[index create update destroy]
        resources :audit_events, only: :index
        resources :products, only: %i[index show create update] do
          member { post :archive }
          resources :variants, only: %i[create update]
          resources :images, only: %i[create show], controller: "product_images"
        end
        resources :collections, only: %i[index create] do
          member { post :products, action: :add_product }
        end
        resources :inventory_items, only: :index do
          member { post :adjustments }
        end
        resources :discount_codes, only: %i[index create]
        resources :shipping_rates, only: %i[index create]
        resources :tax_rates, only: %i[index create]
        resources :orders, only: %i[index show] do
          member { post :fulfillment }
        end
        resources :customers, only: %i[index show]
        get "sales_summary", to: "sales_summaries#show"
      end

      scope "storefront/:handle", module: :storefront do
        get "/", to: "stores#show"
        get "products", to: "products#index"
        get "products/:product_handle", to: "products#show"
        get "images/:id", to: "images#show"
        get "cart", to: "carts#show"
        post "cart/lines", to: "cart_lines#create"
        patch "cart/lines/:id", to: "cart_lines#update"
        delete "cart/lines/:id", to: "cart_lines#destroy"
        post "checkout", to: "checkouts#create"
        get "orders/:number", to: "orders#show"
      end
    end
  end
end
