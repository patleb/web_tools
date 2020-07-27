module RailsAdmin
  class Choose < ActiveType::Object
    include GlobalKey

    attribute :section
    attribute :model
    attribute :prefix
    attribute :label
    attribute :chosen, :hash
    attribute :fields, :array

    with_options presence: true do
      validates :section
      validates :model
      validates :label
      validates :fields
    end

    before_save :save_now

    def self.global_key(section, model, prefix, label = nil)
      label = label&.slugify
      super
    end

    def self.exist?(section:, model:, prefix:, label:)
      Global.exist?(global_key(section, model, prefix, label))
    end

    def self.delete_by(section:, model:, prefix:, label:)
      Global.delete(global_key(section, model, prefix, label))
    end

    def self.group_by_label(section:, model:, prefix:)
      Global.read_multi(global_key_matcher(section, model, prefix)).transform_keys! do |key|
        key.match(/:([^:]+)$/)[1]
      end
    end

    def save_now
      if chosen_label.present?
        old_record = Global.read_record global_key(section, model, prefix, chosen_label)
        old_record.delete if old_record && (fields == old_record.data)
      end

      Global.write_record(global_key, expires: false){ fields }
    end

    def chosen_label
      chosen.try(:[], :label)
    end
  end
end
