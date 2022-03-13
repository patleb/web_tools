module ExtWebpacker
  module Gems
    extend self

    class CoffeeScriptVersion < StandardError; end
    class MissingDependency < StandardError; end
    class MissingGem < StandardError; end

    GEMS_SOURCE_PATH = 'lib/javascript'

    def install
      verify_dependencies!
      source_gems_path.mkdir unless source_gems_path.exist?
      source_gems_path.children.select(&:symlink?).each(&:delete.with(false))
      watched_symlinks = dependencies[:gems].map do |(gem_name, gem_path)|
        path = source_gems_path.join(gem_name)
        path.symlink(gem_path, false)
        path.join("**/*.{js,coffee,css,scss,erb}").to_s # ? png,svg,git,jpeg,jpg
      end
      Webpacker::Compiler.gems_watched_paths = watched_symlinks
      compile_tailwind_config
    end

    def verify_dependencies!
      if package_dependencies.include? 'coffeescript'
        cs_version = `./node_modules/.bin/coffee -v`.strip.split.last
        raise CoffeeScriptVersion, cs_version unless cs_version == '1.12.7'
      end
      missing_dependencies = dependencies[:packages] - package_dependencies
      raise MissingDependency, missing_dependencies.to_a.join(', ') unless missing_dependencies.empty?
    end

    def compile_tailwind_config
      return unless (file = Pathname.new('./tailwind.config.js')).exist?
      tailwind = file.read.gsub(%r{@@/[\w-]+}){ |name| Gem.root(name.delete_prefix('@@/')).to_s }.gsub('@/', './')
      Pathname.new('./tmp/tailwind.config.js').write(tailwind)
    end

    def dependencies
      @dependencies ||= gems.each_with_object({ packages: Set.new, gems: Set.new }) do |gem, dependencies|
        packages, gems = packages_gems(gem)
        missing_gems = []
        gems = ((gems || []) << gem).map do |name|
          next (missing_gems << name) unless (path = Gem.root(name))
          [name, path.join(GEMS_SOURCE_PATH)]
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        dependencies[:gems].merge(gems)
        dependencies[:packages].merge(packages || [])
      end.transform_values(&:to_a).transform_values(&:sort)
    end

    def packages_gems(gem)
      if gem && (package = Gem.root(gem)&.join(GEMS_SOURCE_PATH, 'package.yml'))&.exist?
        packages, gems = YAML.safe_load(package.read).values_at('packages', 'gems')
        (gems || []).each_with_object([Set.new(packages || []), Set.new(gems || [])]) do |gem, result|
          packages, gems = packages_gems(gem)
          result[0].merge(packages || [])
          result[1].merge(gems || [])
        end
      end
    end

    def gems
      @gems ||= Set.new(default_config['gems'] || []).merge(['ext_webpacker'])
    end

    def source_gems_path
      @source_gems_path ||= source_path.join(default_config['source_gems_path'])
    end

    def source_path
      @source_path ||= Pathname.new(default_config['source_path'])
    end

    def default_config
      @default_config ||= YAML.load(Pathname.new('config/webpacker.yml').read)['default']
    end

    def package_dependencies
      @package_dependencies ||= JSON.parse(Pathname.new('package.json').read)['dependencies'].keys
    end
  end
end
