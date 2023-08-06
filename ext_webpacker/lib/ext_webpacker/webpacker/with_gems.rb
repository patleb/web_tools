module Webpacker
  # https://github.com/tailwindlabs/tailwindcss/blob/master/src/lib/expandTailwindAtRules.js#L9-L31
  TAILWIND_EXTRACTOR = <<~JS.strip.indent(6)
    (content) => {
      let results = content.match(/("[^"]*"|'[^']*')/g) || []
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

  class CoffeeScriptVersion < StandardError; end
  class CircularDependency < StandardError; end
  class MissingDependency < StandardError; end
  class MissingGem < StandardError; end

  module WithGems
    # webpacker --profile --json > tmp/stats.json && yarn webpack-bundle-analyzer tmp/stats.json
    def install
      verify_dependencies!
      watched_symlinks = { lib: source_lib_path, vendor: source_vendor_path }.each_with_object([]) do |(type, directory), symlinks|
        directory.mkdir unless directory.exist?
        directory.children.select(&:symlink?).each(&:delete.with(false))
        symlinks.concat(dependencies[:gems].select_map do |name|
          next unless (root = Gem.root(name).join("#{type}/javascript")).exist?
          if type == :vendor
            root.children.map do |root|
              symlink_path(directory, root.basename, root)
            end
          else
            symlink_path(directory, name, root)
          end
        end.flatten)
      end
      if (root = Bundler.root.join('vendor/javascript')).exist?
        watched_symlinks.concat(root.children.map do |root|
          symlink_path(source_vendor_path, root.basename, root)
        end)
      end
      Webpacker::Compiler.gems_watched_paths = watched_symlinks.map do |link|
        link.join("**/*.{js,coffee,css,scss,erb}").to_s # ,png,svg,gif,jpeg,jpg ?
      end
      compile_tailwind_config
    end

    def symlink_path(directory, name, root)
      path = directory.join(name)
      path.symlink(root, false)
    end

    def verify_dependencies!
      if package_dependencies.include? 'coffeescript'
        coffee_version = `node_modules/.bin/coffee -v`.strip.split.last
        raise CoffeeScriptVersion, coffee_version unless coffee_version == '1.12.7'
      end
      missing_dependencies = dependencies[:packages] - package_dependencies
      raise MissingDependency, missing_dependencies.to_a.join(', ') unless missing_dependencies.empty?
    end

    def compile_tailwind_config
      return unless package_dependencies.include?('tailwindcss') && (file = Pathname.new('./tailwind.config.js')).exist?
      tailwind = file.read
      tailwind.sub!(/["']Webpacker::TAILWIND_EXTRACTOR["']/, TAILWIND_EXTRACTOR)
      tailwind.sub!(/["']Webpacker::TAILWIND_DEPENDENCIES["']/, tailwind_dependencies)
      tailwind.gsub!(%r{@@[\w-]+}){ |name| Gem.root(name.tr('@', '')).to_s }
      tailwind.gsub! '@@', Bundler.root.to_s
      Pathname.new('./tmp/tailwind.config.js').write(tailwind)
    end

    def tailwind_dependencies
      (tailwind.merge(dependencies[:tailwind])).map{ |path| "'#{path}'" }.join(",\n      ")
    end

    def dependencies
      @dependencies ||= gems.each_with_object(gems: Set.new, packages: Set.new, tailwind: Set.new) do |name, result|
        gems, packages, tailwind = gems_packages_tailwind(name)
        missing_gems = []
        gems = (gems << name).map do |gem|
          next (missing_gems << gem) unless Gem.exists? gem
          gem
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        result[:gems].merge(gems)
        result[:packages].merge(packages)
        result[:tailwind].merge(tailwind)
      end.transform_values{ |v| v.to_a.sort }
    end

    def gems_packages_tailwind(name)
      if name && (package = Gem.root(name)&.join('lib/javascript/package.yml'))&.exist?
        parent = YAML.safe_load(package.read).values_at('gems', 'packages', 'tailwind').map{ |v| Set.new(v || []) }
        parent[0].each_with_object(parent) do |gem, parent|
          children = gems_packages_tailwind(gem)
          parent.each_with_index{ |v, i| v.merge(children[i]) }
        end
      else
        [[], [], []]
      end
    rescue RuntimeError => e
      if e.message == "can't add a new key into hash during iteration"
        raise CircularDependency, package
      else
        raise
      end
    end

    def gems
      @gems ||= Set.new(['ext_webpacker'] + (default_config['gems'] || []))
    end

    def tailwind
      @tailwind ||= Set.new(default_config['tailwind'] || [])
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
