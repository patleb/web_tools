module Rice
  HOOKS = %i(before_include after_include before_initialize after_initialize initialize).index_with('')
  CONFIGS = %i(cling libs include_dir include rescue_handler)
  MAKEFILE = %i(cflags libs vpaths).index_with('')
  METHOD_ALIAS_KEYWORD = /^(?!(module|class|enum) +[A-Z]).+ +\| +.+/

  class MissingGem < StandardError; end

  module WithFiles
    def require_overrides
      rb_paths.each do |file|
        require file
      end
    end

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
      if (root = vendor_path).exist?
        root.children.map do |root|
          compile_files(root, root.basename)
        end
      end
      if (root = app_path).exist?
        compile_files(root)
      end
    end

    def compile_files(src, dst_name = nil)
      dst_dir = dst_name ? dst_path.join(dst_name) : dst_path
      dst_dir.mkdir_p
      Dir["#{src}/**/*.{h,hpp,ipp,c,cc,cpp}"].each do |file|
        content = ERB.template(file, binding, cpp: true, trim_mode: '-').strip
        has_once = content.include?('#pragma once') || content.include?('#ifndef ')
        is_header = file.end_with? '.h', '.hpp', '.ipp'
        precompiled = file.end_with? '/precompiled.hpp'
        compiled_path = dst_dir.join(file.delete_prefix("#{src}/"))
        compiled_path.dirname.mkdir_p
        compiled_path.open('w') do |f|
          if precompiled
            f.puts include_headers
            f.puts '// precompiled'
          else
            f.puts <<~HEADER if is_header && !has_once
            #pragma once

            HEADER
          end
          excluded_files.each do |excluded|
            content.gsub! %r{^#include *"[^"]+/#{excluded}[/.][^"]+" *$}, ''
          end
          f.puts content
        end
      end
    end

    def hooks
      @hooks ||= gems_config[:hooks]
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
      defs = yml_read(path)
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
      CONFIGS.map{ |name| [name, Set.new(Array.wrap(yml.delete(name)).flatten)] }.to_h
    end

    def merge_defs!(parent, children)
      parent.merge!(children) do |key, parent_val, children_val|
        case key
        when METHOD_ALIAS_KEYWORD
          parent_val
        when ATTRIBUTES_KEYWORDS
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

    def rb_paths
      paths = yml? ? filter(app_path.glob('**/*.rb')) : []
      gems.each_with_object([]) do |name, result|
        next unless (root = name && Gem.root(name))
        next unless root.join('config/rice.yml').exist?
        result.concat(filter(root.glob('lib/rice/**/*.rb')))
      end.concat(paths)
    end

    def other_yml_paths
      paths = yml? ? filter(config_path.glob('**/*.yml')) : []
      gems.each_with_object(paths) do |name, result|
        next unless (root = name && Gem.root(name))
        next unless (config = root.join('config/rice.yml')).exist?
        result << config
        result.concat(filter(root.glob('config/rice/**/*.yml')))
      end
    end

    def no_gems!
      @no_gems = true
      @yml = @default_config = @gems = @gems_config = @hooks = @excluded_files = nil
    end

    def gems
      @gems ||= @no_gems ? (yml.delete(:gems); []) : begin
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
      @yml ||= yml? ? yml_read(yml_path) : {}
    end

    def yml?
      yml_path.exist?
    end

    def filter(files)
      files.reject do |file|
        excluded_files.any? do |excluded|
          file.to_s.include? excluded
        end
      end
    end

    def excluded_files
      @excluded_files ||= Array.wrap(yml.delete(:excluded_files))
    end

    def yml_read(path)
      (YAML.safe_load(ERB.template(path, binding, trim_mode: '-'), aliases: true)&.except('aliases') || {}).to_hwia
    end
  end
end
