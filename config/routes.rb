Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'main#index'

  get '/favicon.ico', to: -> (_) { [404, {}, ['']] }

  # scope path: '/resources', controller: 'resources' do
  #   get '/' => :index
  #   get '/new' => :new
  #   post '/new' => :create
  #   scope path: '/:id' do
  #     get '/' => :show
  #     get '/edit' => :edit
  #     post '/edit' => :update
  #     get '/delete' => :delete
  #     post '/delete' => :destroy
  #   end
  # end

  scope path: '/coffee', controller: 'coffee' do
    get '/' => :basic_template
    match '/sign_in', action: :sign_in, via: [:get, :post]
    match '/company', action: :company, via: [:get, :post]
    get '/error' => :error
  end
  get 'sass', to: 'sass#index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
end
