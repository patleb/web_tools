module Sunzistrano
  VARIABLES = /(-?\{[a-z0-9_]+})/

  class Context < OpenStruct
    attr_reader :sun
    attr_reader :gems

    def initialize(role, **options)
      validate_config_presence!
      @role, @env, @app = role.to_s, Setting.env, Setting.app
      @sun = self
      @gems = {}
      context = Setting.all.to_hwia.merge!(extract_yml(Setting.root)).merge!(options).merge!(role => true)
      require_overrides
      @gems = @gems.to_a.reverse.to_h
      @secrets&.each{ |key| context[key] = Setting.decrypt(context[key]) }
      @replaced&.each{ |key| context[key.delete_suffix(Setting::REPLACE)] = context.delete(key) }
      remove_ivar(:@secrets)
      remove_ivar(:@replaced)
      super(context)
    end

    def attributes
      to_h.reject{ |_, v| (v != false && v.blank?) || v.is_a?(Hash) || v.is_a?(Array) || v.to_s.match?(/(\s|<%.+%>)/) }.merge(
        repo_url: repo_url,
        revision: revision,
        owner_public_key: owner_public_key,
        owner_private_key: owner_private_key&.escape_newlines,
        stage: stage,
        role: role,
        env: env,
        app: app,
        root: Setting.root.to_s,
        linked_dirs: linked_dirs,
        linked_files: linked_files,
        bash_dir: provision_path(BASH_DIR),
        bash_log: provision_path(BASH_LOG),
        defaults_dir: provision_path(DEFAULTS_DIR),
        manifest_dir: provision_path(MANIFEST_DIR),
        manifest_log: provision_path(MANIFEST_LOG),
        metadata_dir: provision_path(METADATA_DIR),
        deploy: deploy.to_b,
        system: system,
        provision: provision.to_b,
        specialize: specialize.to_b,
        rollback: rollback.to_b,
        debug: debug,
        reboot: reboot.to_b,
        force: force.to_b,
      )
    end

    def has_key?(name)
      @table.has_key? name
    end

    def deploy_path(*segments)
      "/home/#{ssh_user}/#{deploy_dir}/#{segments.join('/')}"
    end

    def provision_path(*segments)
      "/home/#{ssh_user}/#{provision_dir}/#{segments.join('/')}"
    end

    def deploy_dir
      deploy ? stage : env
    end

    def provision_dir
      deploy ? "#{stage}/releases/#{revision}" : env
    end

    def debug
      return @debug if defined? @debug
      value = ENV['DEBUG'].presence
      @debug = value == 'trace' ? value : value.to_b
    end

    def system
      self[:system].to_b
    end

    def sudo
      has_key?(:sudo) ? self[:sudo] : !deploy
    end

    def ssh_user
      self[:ssh_user] || (deploy ? deployer_name : owner_name)
    end

    def repo_url
      return @repo_url if defined? @repo_url
      @repo_url = self[:repo_url] || `git config --get remote.origin.url`.strip
    end

    def revision
      return @revision if defined? @revision
      @revision = deploy ? self[:revision] || `git rev-parse origin/#{branch}`.strip : nil
    end

    def servers
      @servers ||= cloud_cluster ? Cloud.cluster_ips : [server_host]
    end

    def owner_public_key
      self[:owner_public_key].presence && "'#{self[:owner_public_key]}'"
    end

    def owner_private_key
      self[:owner_private_key].presence && "'#{self[:owner_private_key]}'"
    end

    def stage
      "#{env}_#{app}"
    end

    def role
      @_role ||= ActiveSupport::StringInquirer.new(@role.to_s)
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(@env.to_s)
    end

    def app
      @_app ||= ActiveSupport::StringInquirer.new(@app.to_s)
    end

    def linked_dirs
      self[:linked_dirs].presence && "'#{self[:linked_dirs].join(' ')}'" || "''"
    end

    def linked_files
      self[:linked_files].presence && "'#{self[:linked_files].join(' ')}'" || "''"
    end

    def role_helpers
      (gems.values.reverse << Setting.root).each do |root|
        helpers(root).sort.each do |file|
          yield "helpers/#{file}", root
        end
      end
    end

    def helpers(root)
      base_dir = Pathname.new(root).join(CONFIG_PATH, 'helpers')
      Dir[base_dir.join('**/*.sh').to_s].map do |file|
        Pathname.new(file).relative_path_from(base_dir).to_s
      end
    end

    def role_recipes(*names)
      recipes = merge_recipes names
      if (reboot = recipes.delete('reboot'))
        recipes << reboot
      end
      if recipe.present?
        recipes.select! do |name|
          name == recipe
        end
      end
      recipes.each do |name|
        next if name.blank?
        id = gsub_variables(name)
        id = "'#{id}'" if id
        if deploy
          next unless name.start_with? 'deploy/'
        else
          next if name.start_with? 'deploy/'
        end
        yield name, id
      end
    end

    def gsub_variables(name)
      has_variables = false
      segments = name.gsub(VARIABLES) do |segment|
        has_variables = true
        dash = '-' if segment.delete_prefix! '-'
        segment.delete_prefix!('{').delete_suffix! '}'
        value = try(segment)
        value = value == true ? segment : value
        value ? "#{dash}#{value}" : ''
      end
      segments if has_variables
    end

    private

    def merge_recipes(names)
      (recipes || []).each_with_object(names.reject(&:blank?)) do |recipe, memo|
        if recipe.is_a? String
          next if recipe.end_with?('-system') && !system
          next memo << recipe
        end
        recipe, options = recipe.first
        case
        when recipe.end_with?('-system') && !system
          next
        when options.nil?
          memo << recipe
        when (sibling = options['before'])
          memo.insert_before(sibling, recipe) if continue(options)
        when (sibling = options['after'])
          memo.insert_after(sibling, recipe) if continue(options)
        when options.has_key?('remove')
          memo.delete(recipe) if options['remove']
        else
          memo << recipe if continue(options)
        end
      end
    end

    def continue(options)
      if options.has_key? 'if'
        is_true = options['if']
        return false unless instance_eval(is_true.to_s)
      end
      if options.has_key? 'unless'
        is_true = options['unless']
        return false if instance_eval(is_true.to_s)
      end
      true
    end

    def extract_yml(root)
      path = root.join(CONFIG_YML)
      return {} unless path.exist?

      yml = YAML.safe_load(ERB.template(path, binding))
      validate_version! yml['lock']
      gems_yml = (['sunzistrano'] + (yml['gems'] || [])).reduce({}) do |gems_yml, name|
        if @gems.has_key? name
          gems_yml
        else
          gems_yml.union! extract_yml(gem_root(name))
        end
      end
      role_yml = (yml['shared'] || {}).union!(yml[@role] || {})
      env_yml = (yml[@env] || {})
      env_yml.union!(yml["#{@role}_#{@env}"] || {})
      role_yml.union!(env_yml)
      if @app
        app_yml = (yml[@app] || {})
        app_yml.union!(yml["#{@env}_#{@app}"] || {})
        app_yml.union!(yml["#{@role}_#{@app}"] || {})
        app_yml.union!(yml["#{@role}_#{@env}_#{@app}"] || {})
        role_yml.union!(app_yml)
      end
      yml = (gems_yml || {}).union!(role_yml)
      yml.each do |key, value|
        (@secrets ||= Set.new) << key if value.is_a?(String) && value.start_with?(Setting::SECRET)
        (@replaced ||= Set.new) << key if key.end_with? Setting::REPLACE
      end
      yml
    end

    def gem_root(name)
      @gems[name] ||= Gem.root(name) or raise "gem [#{name}] not found"
    end

    def require_overrides
      (@gems.values << Setting.root).each do |root|
        path = root.join('config/sunzistrano.rb')
        require path.to_s if path.exist?
      end
    end

    def validate_version!(lock)
      unless lock.nil? || lock == VERSION
        raise "Sunzistrano version [#{VERSION}] is different from locked version [#{lock}]"
      end
    end

    def validate_config_presence!
      raise 'You must have a sunzistrano.yml' unless Setting.root.join(CONFIG_YML).exist?
    end
  end
end
