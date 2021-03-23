module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Xid < Type::UnsignedInteger # :nodoc:
          def type
            :xid
          end
        end
      end
    end
  end
end
