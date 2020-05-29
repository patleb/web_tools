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
      delete_matched
      cleanup
      clear
      clear!
    ), to: 'Global'
  end

  def initialize(options = nil)
    # TODO
  end
end
