module Numo
  def self.build(type, *shape, fill_value: nil)
    narray = const_get(type.to_s).new(*shape)
    fill_value ? narray.fill(fill_value) : narray
  end

  NArray.class_eval do
    def self.types
      @@types ||= ExtRice.config.compile_vars[:numo_types].map{ |name| Numo::Type.const_get(name) }
    end

    def type
      self.class.types[type_id]
    end
  end
end
