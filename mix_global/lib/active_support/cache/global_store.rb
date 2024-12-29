MonkeyPatch.add{['activesupport', 'lib/active_support/cache.rb', '45be0e1167665654fb10fc76aa4bd01b6e1524eb68e8cf4132bbd35a39b1585c']}

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
