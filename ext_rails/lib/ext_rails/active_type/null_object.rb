module ActiveType
  class NullObject < Object
    ID = -1.freeze

    attribute :id, default: ID

    def self.find(*ids)
      return super unless ids.first.to_i == ID
      new
    end
  end
end
