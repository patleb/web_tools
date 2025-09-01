class Setting
  include MixSetting::Type

  CIPHER = 'aes-256-gcm'
  SECRET = '$SECRET'
  METHOD = '$METHOD'
  ALIAS  = '$ALIAS'
  REMOVE = '$REMOVE'
  REPLACE = '!'
  FREED_IVARS = %i(@types @secrets @settings @aliases @methods @removed @replaced)

  def self.secret_key_base
    all[:secret_key_base]
  end

  class << self
    alias_method :key, :secret_key_base

    delegate :[], :[]=, :dig, :has_key?, :key?, :values_at, :slice, :except, :select, :select_map, :reject, to: :all
  end

  def self.to_yaml
    all.to_hash.pretty_yaml
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
      ivars.except(:@default_app).each{ |name| name.end_with?('_was') ? previous << name : current << name }
      current.each{ |name| ivar(name, ivar("#{name}_was")) }
      previous.each{ |name| ivar(name, nil) }
    end
    @all
  end

  def self.load(**options)
    all(false, **options)
  end

  def self.reload(**options)
    all(true, **options)
  end

  def self.all(force = false, env: nil, app: nil, root: nil, freeze: true)
    if force
      current = ivars.except(:@default_app).reject{ |name| name.end_with?('_was') }
      current.each{ |name| ivar("#{name}_was", ivar(name)) }
      current.each{ |name| ivar(name, nil) }
      remove_ivar(:@encryptor)
    end
    @all ||= begin
      @env, @app, @root = (env || self.env).to_s, (app || self.app).to_s, (root || self.root)
      raise 'environment must be specified or configured' unless @env.present?
      @types = {}.to_hwka
      @gems = {}
      @secrets = parse_secrets_yml
      @settings = extract_yml(:settings, @root)
      database = parse_database_yml
      settings = database.merge! parse_settings_yml(@settings)
      settings = @secrets.merge! settings
      require_overrides
      @gems = @gems.to_a.reverse.to_h
      resolve_keywords! settings
      cast_values! settings
      FREED_IVARS.each{ |ivar| remove_ivar(ivar) }
      freeze ? IceNine.deep_freeze!(settings) : settings
    end
  end

  def self.encrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    "#{SECRET} #{encryptor.encrypt_and_sign(value.escape_newlines)}"
  end

  def self.decrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    encryptor.decrypt_and_verify(value.delete_prefix(SECRET).strip).unescape_newlines
  end

  def self.stage
    "#{env}_#{app}"
  end

  def self.local?(*others)
    env? :development, :test, *others
  end

  def self.env?(*names)
    names.any?{ |name| name.to_sym == env.to_sym }
  end

  def self.env
    case
    when @env                then @env
    when ENV['RAILS_ENV']    then ENV['RAILS_ENV']
    when defined?(Rails.env) then Rails.env.to_s
    end
  end

  def self.app?(*names)
    names.any?{ |name| name.to_sym == app.to_sym }
  end

  def self.app
    case
    when @app                then @app
    when ENV['RAILS_APP']    then ENV['RAILS_APP']
    when defined?(Rails.app) then Rails.app.to_s
    else default_app
    end
  end

  def self.root
    case
    when @root                then @root
    when ENV['RAILS_ROOT']    then Pathname.new(ENV['RAILS_ROOT']).expand_path
    when defined?(Rails.root) then Rails.root
    else Pathname.new(Dir.pwd)
    end
  end

  def self.default_app?
    app == default_app
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
    yield *values_at(:db_host, :db_port, :db_database, :db_username, :db_password)
  end

  class << self
    private

    def gem_root(name)
      @gems[name] ||= Gem.root(name) or raise "gem [#{name}] not found"
    end

    def encryptor?
      !!encryptor
    end

    def encryptor
      if defined? @encryptor
        @encryptor
      elsif (key = (@secrets || all)[:secret_key_base])
        size = ActiveSupport::MessageEncryptor.key_len(CIPHER)
        @encryptor = ActiveSupport::MessageEncryptor.new([key[0...(size * 2)]].pack("H*"), cipher: CIPHER)
      else
        @encryptor = false
      end
    end

    def parse_secrets_yml
      extract_yml(:secrets, @root).to_hwka
    end

    def parse_database_yml
      yml = extract_yml(:database, @root)
      scope_database_keys(yml)
    end

    def scope_database_keys(database)
      database.each_with_object({}) do |(key, value), memo|
        memo["db_#{key}"] = value
      end
    end

    def parse_settings_yml(root_or_settings)
      if root_or_settings.is_a? Hash
        settings = root_or_settings
      else
        settings = extract_yml(:settings, root_or_settings)
      end
      gsub_keywords(settings)
    end

    def extract_yml(type, root)
      path = root.join('config', "#{type}.yml")
      return {} unless path.exist?

      case type
      when :database
        yml = YAML.safe_load(gsub_settings(path.read), aliases: true)
      when :settings
        yml = YAML.safe_load(ERB.template(path, binding))
        validate_version! yml['lock']
        @types.merge!(yml['types'] || {})
        gems_yml = (yml['gems'] || []).reduce({}) do |gems_yml, name|
          if @gems.has_key? name
            gems_yml
          else
            gems_yml.union! parse_settings_yml(gem_root(name))
          end
        end
      else # :secrets
        yml = YAML.safe_load(path.read)
      end

      env_yml = (yml['shared'] || {}).union!(yml[@env] || {})
      if @app
        app_yml = (yml[@app] || {}).union!(yml["#{@env}_#{@app}"] || {})
        env_yml.union!(app_yml)
      end
      (gems_yml || {}).union!(env_yml)
    end

    def gsub_settings(content)
      content.gsub(/<%=\s*Setting\[['":]([a-zA-Z_]\w+)['"]?\]\s*%>/) do
        @settings[$1]
      end
    end

    def gsub_keywords(settings)
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
        end
        if key.end_with? REPLACE
          (@replaced ||= Set.new) << key
        end
        memo[key] = value
      end
    end

    def cast_values!(settings)
      @types.each do |name, type|
        settings[name] = cast(settings[name], type)
      end
    end

    def resolve_keywords!(settings)
      @all = settings
      @aliases&.each{ |key, old_name| settings[key] = settings[old_name] }
      @methods&.each{ |key, method_name| settings[key] = public_send(method_name) unless @removed&.include? key }
      @aliases&.each do |key, old_name|
        if @removed&.include? old_name
          settings.delete(old_name)
        else
          settings[key] = settings[old_name]
        end
      end
      @removed&.each{ |key| settings.delete(key) }
      @replaced&.each{ |key| settings[key.delete_suffix(REPLACE)] = settings.delete(key) }
    end

    def require_overrides
      (@gems.values << @root).each do |root|
        path = root.join('config/setting.rb')
        require path.to_s if path.exist?
      end
    end

    def validate_version!(lock)
      unless lock.nil? || lock == MixSetting::VERSION
        raise "Setting version [#{MixSetting::VERSION}] is different from locked version [#{lock}]"
      end
    end
  end
end
