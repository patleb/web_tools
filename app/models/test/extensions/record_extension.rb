module Test
  module Extensions
    class RecordExtension < ActiveType::Record[Record]
      ar_attribute :attr_date, :date
      ar_attribute :attr_date_time, :datetime
      ar_attribute :attr_decimal, :decimal
      ar_attribute :attr_integer, :integer
      ar_attribute :attr_json, :json
      ar_attribute :attr_password, :string
      ar_attribute :attr_string, :string
      ar_attribute :attr_text, :text
      ar_attribute :attr_time, :time
      ar_attribute :attr_value

      attribute :virt_date, :date
      attribute :virt_date_time, :datetime
      attribute :virt_decimal, :decimal
      attribute :virt_integer, :integer
      attribute :virt_json, :json
      attribute :virt_password, :string
      attribute :virt_string, :string
      attribute :virt_text, :text
      attribute :virt_time, :time
      attribute :virt_value

      validates :attr_value, presence: true
    end
  end
end
