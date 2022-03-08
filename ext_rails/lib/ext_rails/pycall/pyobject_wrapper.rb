# TODO nested equality doesn't works well (must cast every objets)
module PyCall
  module PyObjectWrapper
    def to_a
      to_list.to_a
    end

    def to_list
      PyCall.builtins.list.(self)
    end

    def to_dict
      PyCall.builtins.dict.(self)
    end
  end
end
