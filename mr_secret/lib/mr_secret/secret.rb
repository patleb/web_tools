require 'ext_ruby'
require 'active_support/message_encryptor'
require 'erb'
require 'yaml'
require 'inifile'
require 'mr_secret/type'

class Secret
  include MrSecret::Type

  DIRECT = /[a-zA-Z_][a-zA-Z0-9_]+/
  NESTED = /\[[:\[\]a-zA-Z0-9_]+\]/
  CIPHER = 'aes-128-gcm'
  SECRET = '$SECRET'
  METHOD = '$METHOD'
  ALIAS  = '$ALIAS'
  REMOVE = '$REMOVE'

  def self.to_yaml
    all.to_hash.to_yaml(line_width: -1).delete_prefix("---\n")
  end

  def self.[](name)
    value = all[name]
    cast(value, @types[name])
  end

  def self.[]=(name, value)
    all[name] = value
  end

  def self.dig(*names)
    value = all.dig(*names)
    cast(value, @types.dig(*names))
  end

  def self.has_key?(name)
    all.has_key? name
  end
  singleton_class.send :alias_method, :key?, :has_key?

  def self.values_at(*names)
    names.each_with_object([]) do |name, memo|
      memo << self[name]
    end
  end

  def self.slice(*names)
    names.each_with_object({}.with_indifferent_access) do |name, memo|
      memo[name] = self[name]
    end
  end

  def self.except(*names)
    names = names.map(&:to_sym)
    all.each_with_object({}.with_indifferent_access) do |(name, _), memo|
      memo[name] = self[name] unless names.include? name.to_sym
    end
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
      secrets, database = rails_secrets_and_database
      settings = extract_yml(:settings, @root)

      validate_version! settings['lock']

      @gems = {}
      (settings['gems'] || []).each do |name|
        database.merge! parse_settings_yml(secrets, gem_root(name))
      end
      settings = database.merge! parse_settings_yml(secrets, settings)
      settings = secrets.merge! settings
      resolve_keywords(settings)
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
    elsif defined? Rails.env
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
    elsif defined? Rails.application.engine_name
      Rails.application.engine_name.sub(/_application$/, '')
    else
      nil
    end
  end

  def self.rails_root
    if @root
      @root
    elsif ENV['RAILS_ROOT']
      ENV['RAILS_ROOT']
    elsif defined? Rails.root
      Rails.root || ''
    else
      ''
    end
  end

  def self.rails_secrets_and_database
    secrets = extract_yml(:secrets, @root).with_indifferent_access
    database = parse_database_yml(secrets)
    [secrets, database]
  end

  def self.gem_root(name)
    path = (@gems[name] ||= Gem.loaded_specs[name]&.gem_dir)
    path or raise "gem [#{name}] not found"
    Pathname.new(path)
  end

  def self.encryptor?(secrets)
    !!encryptor(secrets)
  end

  def self.encryptor(secrets = nil)
    if defined? @encryptor
      @encryptor
    elsif (key = (secrets || all)[:secret_key_base])
      size = ActiveSupport::MessageEncryptor.key_len(CIPHER)
      @encryptor = ActiveSupport::MessageEncryptor.new([key[0...(size*2)]].pack("H*"), cipher: CIPHER)
    else
      @encryptor = false
    end
  end

  def self.parse_database_yml(secrets)
    yml = extract_yml(:database, @root, secrets)
    scope_database_keys(yml)
  end

  def self.scope_database_keys(database)
    database.each_with_object({}) do |(key, value), memo|
      memo["db_#{key}"] = value
    end
  end

  def self.parse_settings_yml(secrets, root_or_settings)
    if root_or_settings.is_a? Hash
      settings = root_or_settings
    else
      settings = extract_yml(:settings, root_or_settings)
    end

    gsub_keywords(settings, secrets)
  end

  def self.extract_yml(type, root, secrets = nil)
    path = root.join('config', "#{type}.yml")

    return {} unless File.exist?(path)

    yml = (type == :database) ? YAML.load(ERB.new(gsub_rails_secrets(path, secrets)).result) : YAML.safe_load(path.read)
    @types.merge!(yml['types'] || {})
    env_yml = (yml['shared'] || {}).merge!(yml[@env] || {})
    if @app
      app_yml = (yml[@app] || {}).merge!(yml["#{@app}_#{@env}"] || {})
      env_yml.merge!(app_yml)
    end
    env_yml
  end

  def self.gsub_rails_secrets(path, secrets)
    path.read.gsub(/<%=\s*Rails\.application\.secrets\.(#{DIRECT})(#{NESTED})?\s*%>/) do |match|
      eval("secrets[:#{$1}]#{$2}")
    end
  end

  def self.gsub_keywords(settings, secrets)
    settings.each_with_object({}) do |(key, value), memo|
      if value.is_a? String
        if encryptor?(secrets) && value.start_with?(SECRET)
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
          alias_name = value.delete_prefix(ALIAS).strip
          value = memo[alias_name]
        elsif value.start_with? REMOVE
          (@removed ||= Set.new) << key
          next
        end
      end
      memo[key] = value
    end
  end

  def self.resolve_keywords(settings)
    require_initializers
    @all = settings
    @methods&.each{ |key, method_name| settings[key] = send(method_name) unless @removed&.include? key }
    @removed&.each{ |key| settings.delete(key) }
    settings
  end

  def self.require_initializers
    (@gems.values << @root).each do |root|
      path = Pathname.new(root).join('config/initializers/mr_secret.rb')
      require path.to_s if path.exist?
    end
  end

  def self.validate_version!(lock)
    unless lock == MrSecret::VERSION
      raise "Secret version [#{MrSecret::VERSION}] is different from locked version [#{lock}]"
    end
  end
end
