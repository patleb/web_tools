module ActiveType
  class NullObject < Object
    ID = -1.freeze

    attribute :id, default: ID

    def self.find(*ids)
      return super unless ids.first.to_i == ID
      new
    end

    def nil?
      true
    end

    def present?
      false
    end

    def blank?
      true
    end
  end
end
