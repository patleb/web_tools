require 'ext_ruby'
require 'active_support/message_encryptor'
require 'erb'
require 'yaml'
require 'inifile'
require 'mr_setting/type'

class Setting
  include MrSetting::Type

  CIPHER = 'aes-128-gcm'
  SECRET = '$SECRET'
  METHOD = '$METHOD'
  ALIAS  = '$ALIAS'
  REMOVE = '$REMOVE'

  class << self
    delegate :[], :[]=, :dig, :has_key?, :key?, :values_at, :slice, :except, to: :all
  end

  def self.to_yaml
    all.to_hash.to_yaml(line_width: -1).delete_prefix("---\n")
  end

  def self.type_of(name)
    all && (@types[name] || :text).to_sym
  end

  def self.rollback!
    if @all_was
      previous = []
      current  = []
      instance_variables.each{ |ivar| ivar.to_s.end_with?('_was') ? previous << ivar : current << ivar }
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

  def self.all(force = false, env: rails_env, app: rails_app, root: rails_root)
    if force
      current = instance_variables.reject{ |ivar| ivar.to_s.end_with?('_was') }
      current.each{ |ivar| instance_variable_set("#{ivar}_was", instance_variable_get(ivar)) }
      current.each{ |ivar| instance_variable_set(ivar, nil) }
      remove_instance_variable(:@encryptor) if instance_variable_defined? :@encryptor
    end
    @all ||= begin
      raise 'environment must be specified or configured' unless env

      @env = env.to_s
      @app = app
      @root = Pathname.new(root).expand_path
      @types = {}.with_indifferent_access
      @gems = {}
      @secrets = parse_secrets_yml
      @database = parse_database_yml
      settings = extract_yml(:settings, @root)
      settings = @database.merge! parse_settings_yml(settings)
      settings = @secrets.merge! settings
      resolve_keywords! settings
      cast_values! settings
      settings
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

  private_class_method

  def self.rails_env
    if @env
      @env
    elsif ENV['RAILS_ENV']
      ENV['RAILS_ENV']
    elsif defined? Rails
      Rails.env
    else
      nil
    end
  end

  def self.rails_app
    if @app
      @app
    elsif ENV['RAILS_APP']
      ENV['RAILS_APP']
    elsif defined? Rails
      Rails.app
    else
      nil
    end
  end

  def self.rails_root
    if @root
      @root
    elsif ENV['RAILS_ROOT']
      ENV['RAILS_ROOT']
    elsif defined? Rails
      Rails.root || ''
    else
      ''
    end
  end

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
      @encryptor = ActiveSupport::MessageEncryptor.new([key[0...(size*2)]].pack("H*"), cipher: CIPHER)
    else
      @encryptor = false
    end
  end

  def self.parse_secrets_yml
    extract_yml(:secrets, @root).with_indifferent_access
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

    return {} unless File.exist?(path)

    case type
    when :database
      yml = YAML.load(ERB.new(gsub_rails_secrets(path)).result)
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

    env_yml.union!(gems_yml || {})
  end

  def self.gsub_rails_secrets(path)
    path.read.gsub(/<%=\s*Rails\.application\.secrets\.([a-zA-Z_][a-zA-Z0-9_]+)\s*%>/) do
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
          method_name = value.delete_prefix(METHOD).strip
          (@methods ||= {})[key] = (method_name.presence || key)
          next
        elsif value.start_with? ALIAS
          old_name = value.delete_prefix(ALIAS).strip
          (@aliases ||= {})[key] = old_name
          next
        elsif value.start_with? REMOVE
          (@removed ||= Set.new) << key
          next
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
    require_initializers
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
  end

  def self.require_initializers
    (@gems.values << @root).each do |root|
      path = root.join('config/initializers/setting.rb')
      require path.to_s if path.exist?
    end
  end

  def self.validate_version!(lock)
    unless lock.nil? || lock == MrSetting::VERSION
      raise "Setting version [#{MrSetting::VERSION}] is different from locked version [#{lock}]"
    end
  end
end
