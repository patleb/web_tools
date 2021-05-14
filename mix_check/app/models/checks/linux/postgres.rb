module Checks
  module Linux
    class Postgres < WorkerGroup
      def self.list
        [inherited_group]
      end
    end
  end
end
