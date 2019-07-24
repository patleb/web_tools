module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Regclass < Type::String # :nodoc:
          def type
            :regclass
          end
        end
      end
    end
  end
end
