module MixTemplate
  module LayoutHelper
    def extends(layout, &block)
      if block_given?
        super(layout) do
          h_(&block)
        end
      else
        super
      end
    end

    def area(name, content=nil, &block)
      if block_given?
        super(name, content) do
          h_(&block)
        end
      else
        super
      end
    end

    def append(name, content=nil, &block)
      if block_given?
        super(name, content) do
          h_(&block)
        end
      else
        super
      end
    end

    def prepend(name, content=nil, &block)
      if block_given?
        super(name, content) do
          h_(&block)
        end
      else
        super
      end
    end

    def replace(name, content=nil, &block)
      if block_given?
        super(name, content) do
          h_(&block)
        end
      else
        super
      end
    end
  end
end
