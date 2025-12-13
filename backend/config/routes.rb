Rails.application.routes.draw do
  # API routes
  namespace :api do
    # Auth endpoints
    post 'auth/signup', to: 'auth#signup'
    post 'auth/confirm_signup', to: 'auth#confirm_signup'
    post 'auth/resend_confirmation_code', to: 'auth#resend_confirmation_code'

    # Settings endpoints
    resource :settings, only: [:show, :create] do
      collection do
        post 'slack/test', to: 'settings#test_slack'
      end
    end
  end

  # Health check endpoint
  get '/health', to: proc { [200, {}, ['OK']] }
end
