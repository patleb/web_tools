module ActiveRecord::Base::WithJsonb
  extend ActiveSupport::Concern

  class UndefinedTable < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message.match? /PG::UndefinedTable/
    end
  end

  class_methods do
    def serialize(attr_name, class_name_or_coder = Object, **options)
      return if columns_hash[attr_name.to_s].sql_type == 'jsonb'
      super
    rescue UndefinedTable
      super
    end
  end
end
