require 'ext_rails'

module ExtRice
  class Engine < Rails::Engine
    config.before_initialize do |app|
      ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/app/rice")
    end

    initializer 'ext_rice.require_ext' do
      Rice.require_ext unless Rails.env.test?
    end

    initializer 'ext_rice.template', before: 'ext_rice.require_ext' do
      ExtRice.configure do |config|
        config.template[:numeric] = {
          # 'Int8'   => 'int8_t',
          # 'Int16'  => 'int16_t',
          'Int32'  => 'int32_t',
          'Int64'  => 'int64_t2',
          'SFloat' => 'float',
          'DFloat' => 'double',
          'UInt8'  => 'uint8_t',
          # 'UInt16' => 'uint16_t',
          # 'UInt32' => 'uint32_t',
          # 'UInt64' => 'uint64_t2',
        }
        config.template[:generic] = {
          # 'int8_t'    => 'int64_t2',
          # 'int16_t'   => 'int64_t2',
          'int32_t'   => 'int64_t2',
          'int64_t2'  => 'int64_t2',
          'float'     => 'double',
          'double'    => 'double',
          'uint8_t'   => 'uint64_t2',
          # 'uint16_t'  => 'uint64_t2',
          # 'uint32_t'  => 'uint64_t2',
          # 'uint64_t2' => 'uint64_t2',
        }
      end
    end
  end
end
