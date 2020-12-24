class BulkProcessor < Array
  class MaxSizeRequired < ::ArgumentError; end
  class BlockRequired < ::ArgumentError; end

  attr_accessor :max_size
  attr_accessor :processor

  def initialize(max_size = nil, &block)
    raise MaxSizeRequired unless max_size
    raise BlockRequired unless block
    self.max_size = max_size
    self.processor = block
    super()
  end

  def process
    return if size < max_size
    process!
  end

  def process!
    processor.call(self) unless empty?
    clear
  end
  alias_method :finalize, :process!
end
