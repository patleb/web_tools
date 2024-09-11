module Admin
  module Fields
    class JsonArray < Json
      prepend Field::AsArray
    end
  end
end
