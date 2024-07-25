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

  def process(...)
    return if size < max_size
    finalize(...)
  end

  def finalize(...)
    processor.call(self, ...) unless empty?
    clear
  end
end
