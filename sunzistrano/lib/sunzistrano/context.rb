module Sunzistrano
  class Context < OpenStruct
    VARIABLES = /(-?\{[a-z0-9_]+})/

    attr_reader :gems

    def initialize(role: 'system', **options)
      validate_config_presence!
      @role, @env, @app = role, Setting.rails_env, Setting.rails_app
      @gems = {}
      context = Setting.all.merge(extract_yml(Setting.rails_root)).merge! options
      require_overrides
      @replaced&.each{ |key| context[key.delete_suffix(Hash::REPLACE)] = context.delete(key) }
      remove_instance_variable(:@replaced) if instance_variable_defined? :@replaced
      super(context)
    end

    def attributes
      to_h.reject{ |_, v| (v != false && v.blank?) || v.is_a?(Hash) || v.is_a?(Array) || v.to_s.match?(/(\s|<%.+%>)/) }.merge(
        repo_url: repo_url,
        branch: branch,
        revision: revision,
        owner_public_key: owner_public_key,
        owner_private_key: owner_private_key&.escape_newlines,
        stage: stage,
        role: role,
        env: env,
        app: app,
        os_name: os_name,
        os_version: os_version,
        ruby_version: ruby_version,
        linked_dirs: linked_dirs,
        linked_files: linked_files,
        bash_dir: provision_path(BASH_DIR),
        bash_log: provision_path(BASH_LOG),
        defaults_dir: provision_path(DEFAULTS_DIR),
        manifest_dir: provision_path(MANIFEST_DIR),
        manifest_log: provision_path(MANIFEST_LOG),
        metadata_dir: provision_path(METADATA_DIR),
      )
    end

    def has_key?(name)
      @table.has_key? name
    end

    def deploy_path(name)
      "/home/#{ssh_user}/#{stage}/#{name}"
    end

    def provision_path(name)
      "/home/#{ssh_user}/#{provision_dir}/#{name}"
    end

    def provision_dir
      revision ? "#{stage}/releases/#{revision}" : stage
    end

    def sudo
      has_key?(:sudo) ? self[:sudo] : !deploy
    end

    def ssh_user
      self[:ssh_user] || (deploy ? 'deployer' : owner_name)
    end

    def repo_url
      return @repo_url if defined? @repo_url
      @repo_url = self[:repo_url] || `git config --get remote.origin.url`.strip
    end

    def branch
      self[:branch] || 'master'
    end

    def revision
      return @revision if defined? @revision
      @revision = deploy ? `git rev-parse origin/#{branch}`.strip : self[:revision] || '-'
    end

    def servers
      @servers ||= server_cluster ? Cloud.server_cluster_ips : [server_host]
    end

    def server_cluster?
      server_cluster
    end

    def owner_public_key
      self[:owner_public_key].presence && "'#{self[:owner_public_key]}'"
    end

    def owner_private_key
      self[:owner_private_key].presence && "'#{self[:owner_private_key]}'"
    end

    def stage
      "#{env}-#{app}"
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

    def os_name
      self[:os_name] || 'ubuntu'
    end

    def os_version
      self[:os_version] || '20.04'
    end

    def ruby_version
      self[:ruby_version] || RUBY_VERSION
    end

    def linked_dirs
      self[:linked_dirs].presence && "'#{self[:linked_dirs].join(' ')}'" || "''"
    end

    def linked_files
      self[:linked_files].presence && "'#{self[:linked_files].join(' ')}'" || "''"
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
        id = gsub_variables(name)
        id = "'#{id}'" if id
        yield name, id unless name.blank?
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
          next if recipe.end_with?('-system') && !self[:system]
          next memo << recipe
        end
        recipe, action = recipe.first
        action, sibling = action&.first
        next if recipe.end_with?('-system') && !self[:system]
        case action
        when 'remove'
          memo.delete(recipe)
        when 'before'
          memo.insert_before(sibling, recipe)
        when 'after'
          memo.insert_after(sibling, recipe)
        else
          memo << recipe
        end
      end
    end

    def extract_yml(root)
      path = root.join(CONFIG_YML)
      return {} unless path.exist?

      yml = YAML.safe_load(ERB.new(path.read).result(binding))
      validate_version! yml['lock']
      gems_yml = (yml['gems'] || []).reduce({}) do |gems_yml, name|
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
      yml.each_key do |key|
        if key.end_with? Hash::REPLACE
          (@replaced ||= Set.new) << key
        end
      end
      yml
    end

    def gem_root(name)
      @gems[name] ||= Gem.root(name) or raise "gem [#{name}] not found"
    end

    def require_overrides
      @gems.each_value do |root|
        path = root.join('config/sunzistrano.rb')
        require path.to_s if path.exist?
      end
      require 'config/sunzistrano' if File.exist? 'config/sunzistrano.rb'
    end

    def validate_version!(lock)
      unless lock.nil? || lock == VERSION
        raise "Sunzistrano version [#{VERSION}] is different from locked version [#{lock}]"
      end
    end

    def validate_config_presence!
      raise 'You must have a sunzistrano.yml' unless Setting.rails_root.join(CONFIG_YML).exist?
    end
  end
end
