require 'ext_ruby'
require 'active_support/message_encryptor'
require 'erb'
require 'yaml'
require 'inifile'
require 'mix_setting/type'

class Setting
  include MixSetting::Type

  CIPHER = 'aes-256-gcm'.freeze
  SECRET = '$SECRET'.freeze
  METHOD = '$METHOD'.freeze
  ALIAS  = '$ALIAS'.freeze
  REMOVE = '$REMOVE'.freeze
  FREED_IVARS = %i(@types @secrets @database @aliases @methods @removed @replaced)

  class << self
    delegate :[], :[]=, :dig, :has_key?, :key?, :values_at, :slice, :except, :select, :select_map, :reject, to: :all
  end

  def self.to_yaml
    all.to_hash.to_yaml(line_width: -1).delete_prefix("---\n")
  end

  def self.type_of(name)
    all && (@types[name] || :text).to_sym
  end

  def self.with(**options)
    reload(**options)
    yield all
  ensure
    rollback!
  end

  def self.rollback!
    if @all_was
      previous = []
      current  = []
      instance_variables.except(:@default_app).each{ |ivar| ivar.end_with?('_was') ? previous << ivar : current << ivar }
      current.each{ |ivar| instance_variable_set(ivar, instance_variable_get("#{ivar}_was")) }
      previous.each{ |ivar| instance_variable_set(ivar, nil) }
    end
    @all
  end

  def self.load(**options)
    all(false, **options)
  end

  def self.reload(**options)
    all(true, **options)
  end

  def self.all(force = false, env: rails_env, app: rails_app, freeze: true)
    if force
      current = instance_variables.except(:@default_app).reject{ |ivar| ivar.end_with?('_was') }
      current.each{ |ivar| instance_variable_set("#{ivar}_was", instance_variable_get(ivar)) }
      current.each{ |ivar| instance_variable_set(ivar, nil) }
      remove_instance_variable(:@encryptor) if instance_variable_defined? :@encryptor
    end
    @all ||= begin
      raise 'environment must be specified or configured' unless env

      @env = env.to_s
      @app = app&.to_s
      @root = Pathname.new('').expand_path
      @types = {}.with_keyword_access
      @gems = {}
      @secrets = parse_secrets_yml
      @database = parse_database_yml
      settings = extract_yml(:settings, @root)
      settings = @database.merge! parse_settings_yml(settings)
      settings = @secrets.merge! settings
      require_overrides
      resolve_keywords! settings
      cast_values! settings
      FREED_IVARS.each{ |ivar| remove_instance_variable(ivar) if instance_variable_defined? ivar }
      freeze ? IceNine.deep_freeze!(settings) : settings
    end
  end

  def self.all=(settings)
    @all = settings
  end

  def self.encrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    "#{SECRET} #{encryptor.encrypt_and_sign(value.escape_newlines)}"
  end

  def self.decrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    encryptor.decrypt_and_verify(value.delete_prefix(SECRET).strip).unescape_newlines
  end

  def self.rails_stage
    rails_app == default_app ? rails_env : "#{rails_env}:#{rails_app}"
  end

  def self.rails_env
    case
    when @env             then @env
    when ENV['RAILS_ENV'] then ENV['RAILS_ENV']
    when defined?(Rails)  then Rails.env.to_s
    end
  end

  def self.rails_app
    case
    when @app             then @app
    when ENV['RAILS_APP'] then ENV['RAILS_APP']
    when defined?(Rails)  then Rails.app.to_s
    else default_app
    end
  end

  def self.default_app
    @default_app ||= File.read('config/application.rb')[/^module \w+$/].split.last.underscore
  end

  def self.gems
    @gems
  end

  def self.db_url(db_user = nil, db_password = nil)
    db do |host, port, database, username, password|
      "postgresql://#{db_user || username}:#{db_password || password}@#{host}:#{port}/#{database}"
    end
  end

  def self.db
    host, port, database, username, password = values_at(:db_host, :db_port, :db_database, :db_username, :db_password)
    yield(host || '127.0.0.1', port || 5432, database, username, password)
  end

  private_class_method

  def self.gem_root(name)
    @gems[name] ||= Gem.root(name) or raise "gem [#{name}] not found"
  end

  def self.encryptor?
    !!encryptor
  end

  def self.encryptor
    if defined? @encryptor
      @encryptor
    elsif (key = (@secrets || all)[:secret_key_base])
      size = ActiveSupport::MessageEncryptor.key_len(CIPHER)
      @encryptor = ActiveSupport::MessageEncryptor.new([key[0...(size * 2)]].pack("H*"), cipher: CIPHER)
    else
      @encryptor = false
    end
  end

  def self.parse_secrets_yml
    extract_yml(:secrets, @root).with_keyword_access
  end

  def self.parse_database_yml
    yml = extract_yml(:database, @root)
    scope_database_keys(yml)
  end

  def self.scope_database_keys(database)
    database.each_with_object({}) do |(key, value), memo|
      memo["db_#{key}"] = value
    end
  end

  def self.parse_settings_yml(root_or_settings)
    if root_or_settings.is_a? Hash
      settings = root_or_settings
    else
      settings = extract_yml(:settings, root_or_settings)
    end
    gsub_keywords(settings)
  end

  def self.extract_yml(type, root)
    path = root.join('config', "#{type}.yml")
    return {} unless path.exist?

    case type
    when :database
      yml = YAML.safe_load(gsub_rails_secrets(path.read), aliases: true)
    when :settings
      yml = YAML.safe_load(path.read)
      validate_version! yml['lock']
      @types.merge!(yml['types'] || {})
      gems_yml = (yml['gems'] || []).reduce({}) do |gems_yml, name|
        if @gems.has_key? name
          gems_yml
        else
          gems_yml.union! parse_settings_yml(gem_root(name))
        end
      end
    else
      yml = YAML.safe_load(path.read)
    end

    env_yml = (yml['shared'] || {}).union!(yml[@env] || {})
    if @app
      app_yml = (yml[@app] || {}).union!(yml["#{@app}_#{@env}"] || {})
      env_yml.union!(app_yml)
    end
    (gems_yml || {}).union!(env_yml)
  end

  def self.gsub_rails_secrets(content)
    content.gsub(/<%=\s*Rails\.application\.secrets\.([a-zA-Z_]\w+)\s*%>/) do
      @secrets[$1]
    end
  end

  def self.gsub_keywords(settings)
    settings.each_with_object({}) do |(key, value), memo|
      if value.is_a? String
        if encryptor? && value.start_with?(SECRET)
          begin
            value = decrypt(value)
          rescue ActiveSupport::MessageEncryptor::InvalidMessage
            raise ActiveSupport::MessageEncryptor::InvalidMessage,
              "secrets.yml ['secret_key_base'] or settings.yml ['#{key}'] #{SECRET}* is invalid"
          end
        elsif value.start_with? METHOD
          (@methods ||= {})[key] = (value.delete_prefix(METHOD).strip.presence || key)
          next
        elsif value.start_with? ALIAS
          (@aliases ||= {})[key] = value.delete_prefix(ALIAS).strip
          next
        elsif value.start_with? REMOVE
          (@removed ||= Set.new) << key
          next
        end
      else
        if key.end_with? Hash::REPLACE
          (@replaced ||= Set.new) << key
        end
      end
      memo[key] = value
    end
  end

  def self.cast_values!(settings)
    @types.each do |name, type|
      settings[name] = cast(settings[name], type)
    end
  end

  def self.resolve_keywords!(settings)
    @all = settings
    @aliases&.each{ |key, old_name| settings[key] = settings[old_name] }
    @methods&.each{ |key, method_name| settings[key] = send(method_name) unless @removed&.include? key }
    @aliases&.each do |key, old_name|
      if @removed&.include? old_name
        settings.delete(old_name)
      else
        settings[key] = settings[old_name]
      end
    end
    @removed&.each{ |key| settings.delete(key) }
    @replaced&.each{ |key| settings[key.delete_suffix(Hash::REPLACE)] = settings.delete(key) }
  end

  def self.require_overrides
    (@gems.values << @root).each do |root|
      path = root.join('config/setting.rb')
      require path.to_s if path.exist?
    end
  end

  def self.validate_version!(lock)
    unless lock.nil? || lock == MixSetting::VERSION
      raise "Setting version [#{MixSetting::VERSION}] is different from locked version [#{lock}]"
    end
  end
end
