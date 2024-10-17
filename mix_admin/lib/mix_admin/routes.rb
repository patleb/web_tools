# frozen_string_literal: true

module MixAdmin
  module Routes
    def self.root_path(**params)
      append_query(MixAdmin.config.root_path, params)
    end

    def self.draw(mapper)
      mapper.scope path: MixAdmin.config.root_path, controller: 'admin', format: false do
        Admin::Action.all(:root?).each do |action|
          name = action.key
          route_fragment = action.route_fragment? ? name : ''

          define_singleton_method "#{name}_path" do |**params|
            build_path route_fragment, **params
          end

          mapper.match route_fragment, action: name, as: :"admin_#{name}", via: action.http_methods
        end
        mapper.scope '/:model_name' do
          Admin::Action.all(:collection?).each do |action|
            name = action.key
            route_fragment = action.route_fragment? ? name : ''

            define_singleton_method "#{name}_path" do |model_name:, **params|
              if params[:q].is_a? Hash
                params[:q] = params[:q].map{ |(field_name, value)| "{#{field_name}}=#{value}" }.join(' ')
              end
              build_path model_name, route_fragment, **params
            end

            mapper.match route_fragment, action: name, as: :"admin_#{name}", via: action.http_methods
          end
          mapper.scope '/:id' do
            Admin::Action.all(:member?).each do |action|
              name = action.key
              route_fragment = action.route_fragment? ? name : ''

              define_singleton_method "#{name}_path" do |model_name:, id:, **params|
                build_path model_name, id, route_fragment, **params
              end

              mapper.match route_fragment, action: name, as: :"admin_#{name}", via: action.http_methods
            end
          end
        end
      end
    end

    include ExtRails::WithRoutes
  end
end
