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
