module Rice
  HOOKS = %i(before_all after_all before_init after_init).index_with('')
  CONFIGS = %i(dirs libs headers)
  MAKEFILE = %i(cflags libs vpaths).index_with('')
  METHOD_ALIAS_KEYWORD = /^(?!(module|class|enum) +[A-Z]).+ +\| +.+/

  class NestedDependency < StandardError; end
  class MissingGem < StandardError; end

  module WithGems
    delegate :root_vendor, :root_app, :root_test, :test?, :dst_path, :yml_path, :extconf_path, to: 'ExtRice.config'

    def copy_files
      dst_path.rmtree(false)
      dst_path.mkdir_p
      %i(lib vendor).each do |type|
        gems.each do |name|
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
      if (root = root_vendor).exist?
        root.children.map do |root|
          compile_files(root, root.basename)
        end
      end
      if (root = root_app).exist?
        compile_files(root)
      end
      if test? && (root = root_test).exist?
        compile_files(root)
        if executable?
          dst_path.join('ext.cpp').delete(false)
        else
          dst_path.glob('**/*_test.cpp').each(&:delete.with(false))
        end
      end
    end

    def compile_files(src, dst_name = nil)
      dst_dir = dst_name ? dst_path.join(dst_name) : dst_path
      dst_dir.mkdir_p
      Dir["#{src}/**/*.{h,hpp,ipp,c,cc,cpp}"].each do |file|
        content = ERB.template(file, trim_mode: '-').strip
        has_once = content.include?('#pragma once') || content.include?('#ifndef ')
        is_header = file.end_with? '.h', '.hpp', '.ipp'
        compiled_path = dst_dir.join(file.delete_prefix("#{src}/"))
        compiled_path.dirname.mkdir_p
        compiled_path.open('w') do |f|
          f.puts <<~HEADER if is_header && !has_once
          #pragma once

          HEADER
          f.puts content
        end
      end
    end

    def gems_config
      @gems_config ||= other_yml_paths.each_with_object(default_config) do |path, result|
        defs, hooks, *configs, makefile = gem_config(path)
        merge_defs! result[:defs], defs
        merge_strings! result[:hooks], hooks, "\n"
        merge_configs! result, configs
        merge_strings! result[:makefile], makefile, ' '
      end.transform_values{ |v| v.is_a?(Set) ? v.to_a : v }
    end

    def gem_config(path)
      defs = YAML.safe_load(ERB.template(path, binding)).to_hwia
      hooks = extract_strings! defs, HOOKS
      configs = extract_configs! defs
      makefile = extract_strings! defs.delete(:makefile), MAKEFILE
      [defs, hooks, *configs.values_at(*CONFIGS), makefile]
    end

    def default_config
      @default_config ||= {
        defs: yml,
        hooks: extract_strings!(yml, HOOKS),
        **extract_configs!(yml),
        makefile: extract_strings!(yml.delete(:makefile), MAKEFILE),
      }
    end

    def extract_strings!(yml, keys)
      keys.map{ |hook, default| [hook, yml&.delete(hook) || default] }.to_h
    end

    def extract_configs!(yml)
      CONFIGS.map{ |name| [name, Set.new(Array.wrap(yml.delete(name)))] }.to_h
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
            merge_defs! parent_val, children_val
          else
            parent_val
          end
        end
      end
    end

    def merge_strings!(parent, children, separator)
      parent.merge!(children) do |_, parent_val, children_val|
        [children_val.strip, parent_val].compact_blank.join(separator)
      end
    end

    def merge_configs!(parent, children)
      children.each_with_index{ |config, i| parent[CONFIGS[i]].merge(config) }
    end

    def other_yml_paths
      paths = yml_path.exist? ? yml_path.glob('config/rice/**/*.yml') : []
      gems.each_with_object(paths) do |name, result|
        next unless (root = name && Gem.root(name))
        next unless (config = root.join('config/rice.yml')).exist?
        result << config
        result.concat(root.glob('config/rice/**/*.yml'))
      end
    end

    def gems
      @gems ||= begin
        missing_gems = []
        gems = (Set.new(['ext_rice'] + Array.wrap(yml.delete(:gems)))).map do |name|
          next (missing_gems << name) unless Gem.exists? name
          name
        end
        raise MissingGem, missing_gems.join(', ') unless missing_gems.empty?
        gems
      end
    end

    def yml
      @yml ||= if yml_path.exist?
        YAML.safe_load(ERB.template(yml_path, binding)).to_hwia
      else
        {}
      end
    end
  end
end
