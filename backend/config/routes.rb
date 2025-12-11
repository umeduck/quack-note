Rails.application.routes.draw do
  # API routes
  namespace :api do
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
