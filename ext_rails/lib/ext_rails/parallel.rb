module Parallel::WithActiveRecord
  extend ActiveSupport::Concern

  class_methods do
    def map(source, options = {}, &block)
      options = options.dup
      return super if (ar_bases = Array.wrap(options.delete(:ar_base))).empty?
      begin
        super
      ensure
        ar_bases.each{ |ar_base| ar_base.connection.reconnect! }
      end
    end
  end
end

Parallel.prepend Parallel::WithActiveRecord
