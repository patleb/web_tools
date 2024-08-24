MonkeyPatch.add{['activesupport', 'lib/active_support/cache.rb', 'a435ec8911354a0d2418e54145d0a30531fb4a81ec70e2eba403dee81063c846']}

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
