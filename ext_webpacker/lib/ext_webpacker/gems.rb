module ExtWebpacker
  module Gems
    extend self

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
        path.join("**/*{#{watched_extensions}}").to_s
      end
      Webpacker::Compiler.watched_paths.concat(watched_symlinks) # TODO additional_paths
    end

    def verify_dependencies!
      missing_dependencies = dependencies[:packages] - package_dependencies
      raise MissingDependency, missing_dependencies.to_a.join(', ') unless missing_dependencies.empty?
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

    def watched_extensions
      @watched_extensions ||= default_config['extensions'].join(',')
    end

    def additional_paths
      @additional_paths ||= default_config['additional_paths']
    end

    def default_config
      @default_config ||= YAML.load(Pathname.new('config/webpacker.yml').read)['default']
    end

    def package_dependencies
      @package_dependencies ||= JSON.parse(Pathname.new('package.json').read)['dependencies'].keys
    end
  end
end
