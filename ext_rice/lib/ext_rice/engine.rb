module ExtRice
  class Engine < Rails::Engine
    config.before_initialize do |app|
      ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/app/rice")
    end

    initializer 'ext_rice.require_ext' do
      Rice.require_ext unless Rails.env.test?
    end

    initializer 'ext_rice.compile_vars' do
      ExtRice.configure do |config|
        config.compile_vars[:numo] = %w(
          NArray
          SFloat
          DFloat
          Int8
          Int16
          Int32
          Int64
          UInt8
          UInt16
          UInt32
          UInt64
          RObject
          SComplex
          DComplex
          Bit
        )
      end
    end
  end
end
