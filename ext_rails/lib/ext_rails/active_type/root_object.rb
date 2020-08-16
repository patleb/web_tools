module ActiveType
  class RootObject < Object
    ID = -1.freeze

    attribute :id, default: ID

    def self.find(*ids)
      return super unless ids.first.to_i == ID
      new
    end
  end
end
