module Admin
  module Actions
    class Restore < Admin::Action
      def self.weight
        4
      end

      def self.collection?
        true
      end

      def self.bulkable?
        action.trashable?
      end

      def self.navigable?
        false
      end

      def self.http_methods
        [:post]
      end

      def self.route_private?
        true
      end

      def trashable?
        true
      end
    end

    controller_for Restore do
      return on_routing_error unless params[:_restore]
      restored, not_restored = @presenters.each(&:undiscard).partition(&:undiscarded?)
      if restored.any?
        flash[:notice] = admin_notice(restored)
      end
      if not_restored.any?
        flash[:alert] = admin_alert(not_restored)
      end
      redirect_back
    rescue ActiveRecord::RecordInvalid
      redirect_back alert: admin_alert(@presenters)
    end
  end
end
