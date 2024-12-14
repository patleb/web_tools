module Admin
  module Actions
    class Upload < Admin::Action
      def self.collection?
        true
      end

      def self.navigable?
        false
      end

      def self.http_methods
        [:get, :post]
      end

      def self.http_format
        :json
      end

      def self.route_private?
        true
      end

      def section_name
        :edit
      end

      def presenters?
        false
      end
    end

    controller Upload do
      case request.method_symbol
      when :get
        blob_params = params.require(:blob).permit(:uid)
        blob = ActiveStorage::Blob.find_by(**blob_params)
      when :post
        blob_params = params.require(:blob).permit(:filename, :data)
        filename, data = blob_params[:filename], blob_params[:data]
        blob = ActiveStorage::Blob.find_or_create_by_uid! filename, data, backup: @model.backup_upload?
      end
      render json: { blob: { id: blob&.id } }
    end
  end
end
