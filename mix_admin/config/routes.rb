RailsAdmin::Engine.routes.draw do
  controller 'main' do
    RailsAdmin.add_route(:base)

    root action: :index, model_name: RailsAdmin.config.root_model_name.to_admin_param

    RailsAdmin.actions(:root).each do |action|
      RailsAdmin.add_route(:root, action_name = action.name, route_fragment = action.route_fragment)

      match "/#{route_fragment}", action: action_name, as: action_name, via: action.http_methods
    end

    scope ':model_name' do
      RailsAdmin.actions(:collection).each do |action|
        RailsAdmin.add_route(:collection, action_name = action.name, route_fragment = action.route_fragment)

        match "/#{route_fragment}", action: action_name, as: action_name, via: action.http_methods
      end

      RailsAdmin.add_route(:collection, :bulk_action, 'bulk_action')

      post '/bulk_action', action: :bulk_action, as: 'bulk_action'

      scope ':id', format: false, constraints: { id: %r{[^/]+} } do
        RailsAdmin.actions(:member).each do |action|
          RailsAdmin.add_route(:member, action_name = action.name, route_fragment = action.route_fragment)

          match "/#{route_fragment}", action: action_name, as: action_name, via: action.http_methods
        end
      end
    end
  end
end
