module Rice
  HOOKS = %w(before_all after_all before_init after_init).map{ |hook| [hook, ''] }.to_h
  METHOD_ALIAS_KEYWORD = /^(?!(module|class) +[A-Z]).+ +\| +.+/

  class CircularDependency < StandardError; end
  class MissingGem < StandardError; end

  module WithGems
    def copy_files
      dst.rmtree(false)
      dst.mkdir_p
      %i(lib vendor).each do |type|
        dependencies[:gems].each do |name|
          next unless (root = Gem.root(name).join("#{type}/rice")).exist?
          if type == :vendor
            root.children.map do |root|
              compile_files(root, root.basename)
            end
          else
            compile_files(root, name)
          end
        end
      end
      if (root = self.root.join('vendor/rice')).exist?
        root.children.map do |root|
          compile_files(root, root.basename)
        end
      end
      if (root = self.root.join('app/rice')).exist?
        compile_files(root)
      end
    end

    def compile_files(src, dst_name = nil)
      dst_dir = dst_name ? dst.join(dst_name) : dst
      dst_dir.mkdir_p
      Dir["#{src}/**/*.{h,hpp,ipp,c,cc,cpp}"].each do |file|
        content = ERB.new(File.read(file), nil, '-').result.strip
        has_once = content.include?('#pragma once') || content.include?('#ifndef ')
        is_header = file.end_with? '.h', '.hpp', '.ipp'
        compiled_path = dst_dir.join(File.basename(file))
        compiled_path.open('w') do |f|
          f.puts <<~HEADER if is_header && !has_once
          #pragma once

          HEADER
          f.puts content
        end
      end
    end

    def dependencies
      @dependencies ||= gems.each_with_object(gems: Set.new, hooks: extract_hooks!(config), defs: config) do |name, result|
        gems, hooks, defs = gems_hooks_defs(name)
        missing_gems = []
        gems = (gems << name).map do |gem|
          next (missing_gems << gem) unless Gem.exists? gem
          gem
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        result[:gems] = result[:gems].merge(gems)
        merge_hooks! result[:hooks], hooks
        merge_defs! result[:defs], defs
      end.transform_values{ |v| v.is_a?(Set) ? v.to_a.sort : v }
    end

    def gems
      @gems ||= Set.new(['ext_rice'].concat(config.delete('gems') || []).compact)
    end

    def gems_hooks_defs(name)
      if name && (rice = Gem.root(name)&.join('lib/rice.yml'))&.exist?
        defs = YAML.safe_load(rice.read)
        gems = Set.new(defs.delete('gems') || [])
        hooks = extract_hooks! defs
        gems.each_with_object([gems, hooks, defs]) do |gem_name, (gems, hooks, defs)|
          children_gems, children_hooks, children_defs = gems_hooks_defs(gem_name)
          gems.merge(children_gems)
          merge_hooks! hooks, children_hooks
          merge_defs! defs, children_defs
        end
      else
        [[], HOOKS.dup, {}]
      end
    rescue RuntimeError => e
      if e.message == "can't add a new key into hash during iteration"
        raise CircularDependency, rice
      else
        raise
      end
    end

    def merge_hooks!(parent, children)
      parent.merge!(children){ |_, parent_val, children_val| [children_val, parent_val].compact_blank.join("\n") }
    end

    def merge_defs!(parent, children)
      parent.merge!(children) do |key, parent_val, children_val|
        case key
        when METHOD_ALIAS_KEYWORD
          parent_val
        when INCLUDES_KEYWORD, ATTRIBUTES_KEYWORDS
          SortedSet.new(Array.wrap(parent_val)).merge(Array.wrap(children_val)).to_a
        else
          if parent_val.is_a?(Hash) && children_val.is_a?(Hash)
            children_val.deep_merge(parent_val)
          else
            parent_val
          end
        end
      end
    end

    def extract_hooks!(yml)
      HOOKS.map{ |hook, default| [hook, yml.delete(hook) || default] }.to_h
    end

    def config(path = extconf.dirname.sub_ext('.yml'))
      @config ||= YAML.safe_load(path.read) || {}
    end

    def extconf(path = root.join('config/rice/extconf.rb'))
      @extconf ||= path
    end

    def dst(path = tmp_path.join('src'))
      @dst ||= path
    end

    def root
      Bundler.root
    end
  end
end
