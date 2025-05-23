module Numo
  NArray.class_eval do
    def self.types
      @@types ||= ExtRice.config.compile_vars[:numo_types].map{ |name| Numo::Type.const_get(name) }
    end

    def type
      self.class.types[type_id]
    end
  end
end
