module Admin
  module Actions
    class Delete < Admin::Action
      def self.weight
        5
      end

      def self.member?
        true
      end

      def self.bulkable?
        true
      end

      def self.http_methods
        [:get, :post]
      end

      def self.icon
        'trash'
      end

      def trashable?
        params["_#{name}"] == 'trash'
      end
    end

    controller_for Delete do
      def delete
        case request.method_symbol
        when :get
          render :delete
        when :post
          delete_method, delete_action = case
            when params[:_delete] then [:destroy, :delete]
            when params[:_trash]  then [:discard, :trash]
            else return on_routing_error
          end
          processed = @presenters.each(&delete_method)
          if (deleted = processed.select(&:"#{delete_method}ed?")).any?
            flash[:notice] = admin_notice(deleted, delete_action)
          end
          if (not_deleted = processed - deleted).any?
            redirect_back alert: admin_alert(not_deleted, delete_action)
          end
          if _back&.match?(%r{/#{@presenters.first.primary_key_value}(/|$)})
            @_back = @model.allowed_url(:index)
          end
          redirect_back
        end
      end
    end
  end
end
