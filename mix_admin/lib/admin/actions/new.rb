module Admin
  module Actions
    class New < Admin::Action
      def self.weight
        3
      end

      def self.collection?
        true
      end

      def self.http_methods
        [:get, :post]
      end

      def self.icon
        'plus-circle'
      end
    end

    controller New do
      case request.method_symbol
      when :get
        render :new
      when :post
        @presenter.assign_attributes(@attributes) if @attributes.present?
        @presenter.save!
        on_save_success
      end
    end
  end
end
