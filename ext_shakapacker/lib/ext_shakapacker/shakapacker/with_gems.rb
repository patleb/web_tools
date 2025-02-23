module Shakapacker
  # https://github.com/tailwindlabs/tailwindcss/blob/master/src/lib/expandTailwindAtRules.js#L9-L31
  TAILWIND_CONTENT_EXTRACT = <<~JS.strip.indent(6)
    (content) => {
      let classes = new Set
      let result = content.match(/("[^"\\n,]+"|'[^'\\n,]+')/g) || []
      result.forEach(v => {
        v = v.slice(1, -1)
        if (v.match(/^[#.]/)) {
          classes = classes.union(new Set(v.split('.')))
        } else if (v.includes(' ')) {
          classes = classes.union(new Set(v.split(' ')))
        } else {
          classes.add(v)
        }
      })
      classes = Array.from(classes).filter(v => v.match(/^-?[a-z]/))
      return classes
    }
  JS
  TAILWIND_CONTENT_FILES = Set.new([
    '@/app/helpers/**/*.rb',
    '@/app/javascript/**/*.{js,coffee}',
    '@/app/presenters/**/*.rb',
    '@/app/views/**/*.html.{erb,ruby}',
  ])
  GEM_ALIAS =
  KEYS = %i(gems packages tailwind)

  class CoffeeScriptVersion < StandardError; end
  class NestedDependency < StandardError; end
  class MissingDependency < StandardError; end
  class MissingGem < StandardError; end

  module WithGems
    # shakapacker --profile --json > tmp/stats.json && yarn webpack-bundle-analyzer tmp/stats.json
    def install
      verify_dependencies!
      watched_symlinks = { lib: source_lib_path, vendor: source_vendor_path }.each_with_object([]) do |(type, directory), symlinks|
        directory.mkdir unless directory.exist?
        directory.children.select(&:symlink?).each(&:delete.with(false))
        symlinks.concat(gems_config[:gems].select_map do |name|
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
      Shakapacker::BaseStrategy.gems_watched_paths = watched_symlinks.map do |link|
        link.join('**/*.{js,coffee,css,scss,erb}').to_s # ,png,svg,gif,jpeg,jpg ?
      end
      if package_dependencies.include? 'tailwindcss'
        compile_tailwind_config
        compile_tailwind_classes if ENV['COMPILE_TAILWIND_CLASSES']
      end
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
      missing_dependencies = gems_config[:packages] - package_dependencies
      raise MissingDependency, missing_dependencies.to_a.join(', ') unless missing_dependencies.empty?
    end

    def compile_tailwind_config
      return unless (file = Pathname.new('./tailwind.config.js')).exist?
      config = file.read
      config.gsub! /^ *(?:import +|require\()["']([^"']+)["']\)? *$/ do
        path = $1.end_with?('.js') ? $1.dup : "#{$1}.js"
        gsub_paths! path
        Pathname.new(path).read
      end
      config.sub!(/["']Shakapacker::TAILWIND_CONTENT_EXTRACT["']/, TAILWIND_CONTENT_EXTRACT)
      config.sub!(/["']Shakapacker::TAILWIND_CONTENT_FILES["'],?/, tailwind_content_files.map{ "'#{it}'"}.join(",\n      "))
      gsub_paths! config
      Pathname.new('./tmp/tailwind.config.js').write(config)
    end

    def compile_tailwind_classes
      paths = tailwind_content_files + ['@/app/javascript/**{,/*/**}/*.{js,coffee,css,scss,erb}']
      classes = paths.each_with_object(SortedSet.new) do |path, result|
        path = path.dup
        gsub_paths! path
        Dir[path].each do |file|
          next unless (values = Pathname.new(file).read.scan(/("[^"\n,]+"|'[^'\n,]+'|@apply [^;]+;)/))
          values.each do |value|
            v = value.first
            if v.match? /^["']/
              v = v[1..-2]
              next result.merge(v.split('.')) if v.match? /^[#.]/
            else
              v = v['@apply '.size..-2]
            end
            next result.merge(v.split(' ')) if v.include? ' '
            result << v
          end
        end
      end.select_map{ |v| v&.match?(/^-?[a-z]/) && "'#{v.tr("'", '"')}'" }
      Pathname.new('./tmp/tailwind.classes.js').write(
        "const tailwind_classes = [\n" \
          "#{classes.join(",\n").indent(2)}\n" \
        "]"
      )
    end

    def tailwind_content_files
      TAILWIND_CONTENT_FILES + Array.wrap(default_config['tailwind']) + gems_config[:tailwind]
    end

    def gsub_paths!(string)
      string.gsub! '@/', "\\1#{Bundler.root.to_s}/"
      string.gsub!(%r{@@[\w-]+}){ |name| Gem.root(name.tr('@', '')).to_s }
    end

    def gems_config
      @gems_config ||= gems.each_with_object(KEYS.index_with{ Set.new }) do |name, result|
        gems, *others = gem_config(name)
        missing_gems = []
        gems = (gems << name).map do |gem|
          next (missing_gems << gem) unless Gem.exists? gem
          gem
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        result[:gems].merge(gems)
        others.each.with_index(1) do |other, i|
          result[KEYS[i]].merge(other)
        end
      end.transform_values{ |v| v.to_a.sort }
    end

    # NOTE can have only one nested level per :gems entry
    def gem_config(name)
      if name && (config = Gem.root(name)&.join('lib/javascript/shakapacker.yml'))&.exist?
        parent = YAML.safe_load(config.read).values_at(*KEYS.map(&:to_s)).map{ |v| Array.wrap(v).to_set }
        parent[0].each_with_object(parent) do |gem, parent|
          children = gem_config(gem)
          parent.each_with_index{ |v, i| v.merge(children[i]) }
        end
      else
        KEYS.map{ [] }
      end
    rescue RuntimeError => e
      if e.message == "can't add a new key into hash during iteration"
        raise NestedDependency, config
      else
        raise
      end
    end

    def gems
      @gems ||= Set.new(['ext_shakapacker'] + Array.wrap(default_config['gems']))
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
      @default_config ||= YAML.load(Pathname.new('config/shakapacker.yml').read, aliases: true)['default']
    end

    def package_dependencies
      @package_dependencies ||= JSON.parse(Pathname.new('package.json').read)['dependencies'].keys
    end
  end
end
