module Admin
  module Fields
    class StringArray < String
      prepend Field::AsArray
    end
  end
end
