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
          deleted, not_deleted = @presenters.each(&delete_method).partition(&:"#{delete_method}ed?")
          if deleted.any?
            flash[:notice] = admin_notice(deleted, delete_action)
          end
          if not_deleted.any?
            flash[:alert] = admin_alert(not_deleted, delete_action)
          elsif _back&.match?(%r{/#{@presenters.first.primary_key_value}(/|$)})
            @_back = @model.allowed_url(:index)
          end
          redirect_back
        end
      rescue ActiveRecord::RecordInvalid
        redirect_back alert: admin_alert(@presenters, delete_action)
      end
    end
  end
end
