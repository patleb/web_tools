module RailsAdmin
  module Config
    module Actions
      class << self
        def all(scope = :all, **bindings)
          actions =
            case scope
            when :all            then @@actions
            when :root           then @@actions.select(&:root?)
            when :collection     then @@actions.select(&:collection?)
            when :bulkable       then @@actions.select(&:bulkable?)
            when :bulkable_trash then @@actions.select(&:bulkable_trash?)
            when :member         then @@actions.select(&:member?)
            end
          actions = actions.stable_sort_by(&:weight).map!{ |action| action.with(bindings) }
          Current.controller ? actions.select(&:visible?) : actions
        end

        def find(custom_key, **bindings)
          if (action = @@actions.find{ |a| a.custom_key == custom_key })
            action = action.with(bindings)
            Current.controller ? (action if action.visible?) : action
          end
        end

        def reset
          @@actions = nil
        end

        def init_actions!
          require_rel 'actions'
          engine_actions.each{ |action| register(action) }
        end

        def register(action)
          klass = const_get(action.camelize)
          self.class.define_method action do |&block|
            add_action_custom_key(klass.new, &block)
          end
        end

        private

        def add_action_custom_key(action, &block)
          action.instance_eval(&block) if block_given?
          @@actions ||= []
          if @@actions.map(&:custom_key).include? action.custom_key
            raise "Action #{action.custom_key} already exists. Please change its custom key."
          else
            @@actions << action
          end
        end

        def engine_actions
          @_engine_actions ||= Dir[RailsAdmin::Engine.root.join('lib/rails_admin/config/actions/*.rb')].map do |action|
            action.match(/\/(\w+)\.rb$/)[1]
          end.except('base')
        end
      end
    end
  end
end
