module ActionDispatch::Routing::RouteSet::WithoutFormat
  def draw(&block)
    super do
      scope format: false do
        instance_exec(&block)
      end
    end
  end

  def append(&block)
    super do
      scope format: false do
        instance_exec(&block)
      end
    end
  end

  def prepend(&block)
    super do
      scope format: false do
        instance_exec(&block)
      end
    end
  end
end

ActionDispatch::Routing::RouteSet.prepend ActionDispatch::Routing::RouteSet::WithoutFormat
