module Db
  module Pg
    class DropAll < Base
      def drop_all
        psql 'DROP OWNED BY CURRENT_USER'
      end
    end
  end
end
