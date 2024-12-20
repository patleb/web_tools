MonkeyPatch.add{['activesupport', 'lib/active_support/cache.rb', '2d1e6f0b4973371bf10017c07790ca807c936d28ec074fc15c41da0bfa3065a9']}

module ActiveSupport::Cache
  class GlobalStore
    delegate *%i(
      exist?
      fetch
      fetch_multi
      read
      read_multi
      write
      write_multi
      increment
      decrement
      delete
      delete_multi
      delete_matched
      cleanup
      clear
    ), to: 'Global'

    def initialize(options = nil)
    end

    def silence!
    end

    def mute
    end
  end
end
