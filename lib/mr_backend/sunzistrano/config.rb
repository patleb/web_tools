module Sunzistrano
  Config.class_eval do
    def swap_size
      @_swap_size ||= (self[:swap_size] || '1024M')
    end
  end
end
