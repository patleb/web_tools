module ExtMinitest
  class Engine < ::Rails::Engine
    Gem.loaded_specs["ext_minitest"].dependencies.each do |d|
      begin
        require d.name
      rescue LoadError => e
        # Put exceptions here.
      end
    end
  end
end
