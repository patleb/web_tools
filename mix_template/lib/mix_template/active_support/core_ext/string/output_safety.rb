module ActiveSupport
  SafeBuffer.class_eval do
    def initialize(str = "")
      @html_safe = true
      super(str.to_s)
    end
  end
end
