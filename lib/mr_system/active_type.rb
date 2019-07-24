### References
# https://github.com/makandra/active_type/issues/32

require 'active_type/virtual_attributes'
require 'mr_system/active_type/extended_record/inheritance'
require 'mr_system/active_type/type_caster'
require 'mr_system/active_type/virtual_attributes'

module ActiveType
  Object.class_eval do
    def type_for_attribute(attribute)
      virtual_columns_hash[attribute]
    end
  end
end
