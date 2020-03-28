# TODO https://api.rubyonrails.org/classes/ActiveRecord/Store.html
module ActiveRecord::Base::WithJsonAttribute
  extend ActiveSupport::Concern

  prepended do
    class_attribute :jsonb_accessors
  end

  class_methods do
    def json_attribute(field_types)
      jsonb_accessor(:json_data, field_types)
    end

    def jsonb_accessor(jsonb_attribute, field_types)
      self.jsonb_accessors ||= {}.with_indifferent_access
      self.jsonb_accessors[jsonb_attribute] ||= []
      self.jsonb_accessors[jsonb_attribute].concat field_types.keys
      super
    end
  end
end
