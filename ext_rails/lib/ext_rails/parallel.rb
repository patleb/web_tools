module Parallel::WithActiveRecord
  extend ActiveSupport::Concern

  class_methods do
    def map(source, options = {}, &block)
      options = options.dup
      return super if (ar_bases = Array.wrap(options.delete(:ar_base))).empty?
      begin
        super(source, options) do |*args|
          @ar_reconnected ||= ar_bases.map{ |ar_base| ar_base.connection.reconnect! } || true
          block.call(*args)
        end
      ensure
        ar_bases.map{ |ar_base| ar_base.connection.reconnect! }
      end
    end
  end
end

Parallel.prepend Parallel::WithActiveRecord
