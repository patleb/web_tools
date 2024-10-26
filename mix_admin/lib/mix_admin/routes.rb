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
              params[:q] = format_query_param(params[:q])
              build_path model_name, route_fragment, **params
            end

            mapper.match route_fragment, action: name, as: :"admin_#{name}", via: action.http_methods
          end
          mapper.scope '/:id' do
            Admin::Action.all(:member?).each do |action|
              name = action.key
              default_id = action.bulkable? ? 'bulk' : nil
              route_fragment = action.route_fragment? ? name : ''

              define_singleton_method "#{name}_path" do |model_name:, id: default_id, **params|
                raise 'missing keyword: :id' if id.nil?
                build_path model_name, id, route_fragment, **params
              end

              mapper.match route_fragment, action: name, as: :"admin_#{name}", via: action.http_methods
            end
          end
        end
      end
    end

    def self.format_query_param(q)
      return q unless q.is_a? Hash
      q = q.map do |(name, value)|
        value = "^#{value.gsub(/\s/, '\ ')}$" if value.is_a? String
        "{#{name}}=#{value}"
      end
      q.join(' ')
    end

    include ExtRails::WithRoutes
  end
end
