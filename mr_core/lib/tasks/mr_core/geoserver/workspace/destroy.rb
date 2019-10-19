module Geoserver
  module Workspace
    class Destroy < Base
      def destroy
        delete("workspaces/#{workspace_name}", recurse: true)
      end
    end
  end
end
