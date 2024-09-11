module Admin
  class Model::VirtualColumn < Model::Column
    def type
      if serialized? @name
        :serialized
      else
        @column.ivar(:@type_caster).ivar(:@type) || :string
      end
    end

    def virtual?
      true
    end
  end
end
