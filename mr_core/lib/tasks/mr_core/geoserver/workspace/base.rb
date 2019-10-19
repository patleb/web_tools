module Geoserver
  module Workspace
    class Base < Base
      def workspace_name
        @workspace ||= Rails.application.name
      end
    end
  end
end
