module Parallel::WithActiveRecord
  extend ActiveSupport::Concern

  class_methods do
    def map(source, options = {}, &block)
      return super if Rails.env.test?
      options = options.dup
      before = options.delete(:before)
      return super if (ar_bases = Array.wrap(options.delete(:reconnect))).empty?
      begin
        if before
          super(source, options) do |*args|
            @ar_reconnected ||= ar_bases.map{ |ar_base| ar_base.connection.reconnect! } || true
            block.call(*args)
          end
        else
          super
        end
      ensure
        ar_bases.each{ |ar_base| ar_base.connection.reconnect! }
      end
    end
  end
end

Parallel.prepend Parallel::WithActiveRecord
