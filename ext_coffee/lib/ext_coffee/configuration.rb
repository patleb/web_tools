module ExtCoffee
  has_config do
    attr_reader :routes

    def routes
      @routes ||= {}
    end
  end
end
