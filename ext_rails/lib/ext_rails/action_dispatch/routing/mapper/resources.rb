module ActionDispatch::Routing::Mapper::Resources
  DEFAULT_RESOURCES = %i(index new create show edit update delete destroy)

  def simple_resources(path:, controller: path.delete_prefix('/'), only: nil, except: nil, **)
    available_actions = only ? Array(only).map(&:to_sym) : DEFAULT_RESOURCES
    actions = Set.new(except ? available_actions - Array(except).map(&:to_sym) : available_actions)

    scope(path: path, controller: controller, **) do
      get '/' => :index,            as: :"#{controller}_index"                 if actions.include? :index
      get '/new' => :new,           as: :"#{controller}_new"                   if actions.include?(:new) && (new = true)
      post '/new' => :create,       as:(:"#{controller}_new" unless new)       if actions.include? :create
      scope path: '/:id' do
        get '/' => :show,           as: :"#{controller}_show"                  if actions.include? :show
        get '/edit' => :edit,       as: :"#{controller}_edit"                  if actions.include?(:edit) && (edit = true)
        post '/edit' => :update,    as:(:"#{controller}_edit" unless edit)     if actions.include? :update
        get '/delete' => :delete,   as: :"#{controller}_delete"                if actions.include?(:delete) && (delete = true)
        post '/delete' => :destroy, as:(:"#{controller}_delete" unless delete) if actions.include? :destroy
      end
    end
  end
end
