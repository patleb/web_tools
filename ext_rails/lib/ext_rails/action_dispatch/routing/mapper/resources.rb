module ActionDispatch::Routing::Mapper::Resources
  DEFAULT_RESOURCES = %i(index new create show edit update delete destroy)

  def simple_resources(path:, controller: path.delete_prefix('/'), only: nil, except: nil, **)
    available_actions = only ? Array(only).map(&:to_sym) : DEFAULT_RESOURCES
    actions = Set.new(except ? available_actions - Array(except).map(&:to_sym) : available_actions)

    scope(path: path, controller: controller, **) do
      get '/' => :index if actions.include? :index
      get '/new' => :new if actions.include? :new
      post '/new' => :create if actions.include? :create
      scope path: '/:id' do
        get '/' => :show if actions.include? :show
        get '/edit' => :edit if actions.include? :edit
        post '/edit' => :update if actions.include? :update
        get '/delete' => :delete if actions.include? :delete
        post '/delete' => :destroy if actions.include? :destroy
      end
    end
  end
end
