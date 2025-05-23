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
        config.compile_vars[:numeric_types] = {
          'Int8'   => 'int8_t',
          'Int16'  => 'int16_t',
          'Int32'  => 'int32_t',
          'Int64'  => 'int64_t2',
          'SFloat' => 'float',
          'DFloat' => 'double',
          'UInt8'  => 'uint8_t',
          'UInt16' => 'uint16_t',
          'UInt32' => 'uint32_t',
          'UInt64' => 'uint64_t2',
        }
        config.compile_vars[:numo_types] = %w(
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
