module ExtWebpacker
  module Gems
    extend self

    class CoffeeScriptVersion < StandardError; end
    class MissingDependency < StandardError; end
    class MissingGem < StandardError; end

    # https://github.com/tailwindlabs/tailwindcss/blob/master/src/lib/expandTailwindAtRules.js#L9-L31
    TAILWIND_EXTRACTOR = <<~JS.strip.indent(6)
      (content) => {
        let results = content.match(/("[^"]+"|'[^']+')/g) || []
        results = results.map(v => {
          v = v.slice(1, -1)
          if (v.match(/^[#.]/)) {
            v = v.split('.')
          } else if (v.includes(' ')) {
            v = v.split(' ')
          }
          return v
        }).flat()
        return results
      }
    JS

    # webpacker --profile --json > tmp/stats.json && yarn webpack-bundle-analyzer tmp/stats.json
    def install
      verify_dependencies!
      watched_symlinks = { lib: source_lib_path, vendor: source_vendor_path }.each_with_object([]) do |(type, directory), symlinks|
        directory.mkdir unless directory.exist?
        directory.children.select(&:symlink?).each(&:delete.with(false))
        symlinks.concat(dependencies[:gems].select_map do |name|
          root = Gem.root(name).join("#{type}/javascript")
          next unless root.exist?
          if type == :vendor
            root.children.map do |root|
              symlink_path(directory, root.basename, root)
            end
          else
            symlink_path(directory, name, root)
          end
        end.flatten)
      end
      Webpacker::Compiler.gems_watched_paths = watched_symlinks
      compile_tailwind_config
    end

    def symlink_path(directory, name, root)
      path = directory.join(name)
      path.symlink(root, false)
      path.join("**/*.{js,coffee,css,scss,erb}").to_s # ,png,svg,gif,jpeg,jpg ?
    end

    def verify_dependencies!
      if package_dependencies.include? 'coffeescript'
        coffee_version = `./node_modules/.bin/coffee -v`.strip.split.last
        raise CoffeeScriptVersion, coffee_version unless coffee_version == '1.12.7'
      end
      missing_dependencies = dependencies[:packages] - package_dependencies
      raise MissingDependency, missing_dependencies.to_a.join(', ') unless missing_dependencies.empty?
    end

    def compile_tailwind_config
      return unless package_dependencies.include?('tailwindcss') && (file = Pathname.new('./tailwind.config.js')).exist?
      tailwind = file.read
      tailwind.sub!(/["']ExtWebpacker::Gems::TAILWIND_EXTRACTOR["']/, TAILWIND_EXTRACTOR)
      tailwind.sub!(/["']ExtWebpacker::Gems::TAILWIND_DEPENDENCIES["']/, tailwind_dependencies)
      tailwind.gsub!(%r{@@[\w-]+}){ |name| Gem.root(name.tr('@', '')).to_s }
      Pathname.new('./tmp/tailwind.config.js').write(tailwind)
    end

    def tailwind_dependencies
      dependencies[:tailwind].map{ |path| "'#{path}'" }.join(",\n      ")
    end

    def dependencies
      @dependencies ||= gems.each_with_object(packages: Set.new, gems: Set.new, tailwind: Set.new) do |gem, result|
        packages, gems, tailwind = packages_gems_tailwind(gem)
        missing_gems = []
        gems = ((gems || []) << gem).map do |name|
          next (missing_gems << name) unless Gem.exists? name
          name
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        result[:gems].merge(gems)
        result[:packages].merge(packages || [])
        result[:tailwind].merge(tailwind || [])
      end.transform_values(&:to_a).transform_values(&:sort)
    end

    def packages_gems_tailwind(name)
      if name && (package = Gem.root(name)&.join('lib/javascript/package.yml'))&.exist?
        parent = YAML.safe_load(package.read).values_at('packages', 'gems', 'tailwind').map{ |v| Set.new(v || []) }
        (parent[1] || []).each_with_object(parent) do |gem, result|
          children = packages_gems_tailwind(gem)
          result.each_with_index{ |v, i| v.merge(children[i] || []) }
        end
      end
    end

    def gems
      @gems ||= Set.new(default_config['gems'] || []).merge(['ext_webpacker'])
    end

    def source_lib_path
      @source_lib_path ||= source_path.join('lib')
    end

    def source_vendor_path
      @source_vendor_path ||= source_path.join('vendor')
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
