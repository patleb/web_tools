module Admin
  class Model::Attribute < Model::Column
    def type
      if serialized? @name
        :serialized
      else
        @klass.type_for_attribute(@name).type || :string
      end
    end

    def virtual?
      true
    end
  end
end
