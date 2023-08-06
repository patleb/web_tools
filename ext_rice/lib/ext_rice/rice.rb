module Rice
  extend WithGems

  RB_CONSTANT = /((::)?[A-Z]\w*)+/
  CPP_CONSTANT = /((::)?[a-zA-Z][\w <:>]*)+/
  ALIAS = / +\| +/
  INHERIT = / +< +/
  STATIC = /^static +/
  SCOPE_KEYWORDS = /^(module|class) +#{RB_CONSTANT}(#{ALIAS}#{CPP_CONSTANT})?(#{INHERIT}#{CPP_CONSTANT})?$/
  CONSTANT_KEYWORD = /^[A-Z_][A-Z0-9_]+$/
  INCLUDES_KEYWORD = 'include'
  ATTRIBUTES_KEYWORDS = /^c?attr_(accessor|reader|writer)$/
  METHODS_KEYWORD = 'def'

  def self.create_makefile(dry_run: false, search_paths: [])
    copy_files

    require_numo if $numo
    yield(dst) if block_given?

    compile_ext

    unless dry_run
      $CXXFLAGS += " -std=c++17 $(optflags) -march=native"
      $srcs = Dir["#{dst}/**/*.cpp"]
      $VPATH.concat(search_paths.map(&:to_s))
      Kernel.create_makefile('ext', dst.to_s)
    end
  end

  def self.require_numo
    require "numo/narray"
    numo = File.join(Gem.loaded_specs["numo-narray"].require_path, "numo")
    find_header! "numo/narray.h", numo
    find_header! "numo/numo.hpp", dst
  end

  def self.compile_ext
    cpp_path = dst.join('ext.cpp')
    hooks = dependencies[:hooks]
    cpp_path.open('w') do |f|
      f.puts <<~CPP
        #{hooks['before_all'].strip}
        #include "all.hpp"
        #{hooks['after_all'].strip}

        extern "C"
        void Init_ext() {
          #{hooks['before_init'].strip}
      CPP
      define_properties(f, nil, dependencies[:defs])
      f.puts <<~CPP
          #{hooks['after_init'].strip}
        }
      CPP
    end
  end

  def self.define_properties(f, parent_var, hash)
    hash.each do |keyword, body|
      # TODO enum (symbols), struct, exception, return, etc.
      case keyword
      when SCOPE_KEYWORDS
        define_self(f, parent_var, keyword, body)
      when CONSTANT_KEYWORD
        define_constant(f, parent_var, keyword, body)
      when INCLUDES_KEYWORD
        define_includes(f, parent_var, body)
      when ATTRIBUTES_KEYWORDS
        define_attributes(f, parent_var, keyword, body)
      when METHODS_KEYWORD
        define_methods(f, parent_var, body)
      else
        raise "invalid keyword [#{keyword}]"
      end
    end
  end

  def self.define_self(f, parent_var, scope, body)
    case body
    when Hash
      parent_var = define_scope(f, parent_var, scope)
      define_properties(f, parent_var, body)
    when nil
      define_scope(f, parent_var, scope)
    else
      raise "invalid body type [#{body.class.name}]"
    end
  end

  def self.define_scope(f, parent_var, scope)
    scope_type, scope_name = scope.split(/ +/, 2)
    return define_module(f, parent_var, scope_name) if scope_type == 'module'

    scope_name, scope_alias = scope_name.split(ALIAS, 2)
    if scope_alias
      scope_alias, scope_base = scope_alias.split(INHERIT, 2)
      cpp_class = scope_base ? "<#{scope_alias}, #{scope_base}>" : "<#{scope_alias}>"
    else
      scope_alias = extract_full_scope_alias(parent_var, scope_name)
    end
    class_type = cpp_class ? "Data_Type<#{scope_alias}>" : 'Class'
    scope_var = build_scope_var('class', scope_alias)
    if parent_var
      f.puts <<~CPP.squish.indent(2)
        Rice::#{class_type} #{scope_var} = Rice::define_class_under#{cpp_class}(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.squish.indent(2)
        Rice::#{class_type} #{scope_var} = Rice::define_class#{cpp_class}("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_module(f, parent_var, scope_name)
    scope_alias = extract_full_scope_alias(parent_var, scope_name)
    scope_var = build_scope_var('module', scope_alias)
    if parent_var
      f.puts <<~CPP.indent(2)
        Rice::Module #{scope_var} = Rice::define_module_under(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.indent(2)
        Rice::Module #{scope_var} = Rice::define_module("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_constant(f, scope_var, name, value)
    raise "can't define a constant on the global scope" unless scope_var
    f.puts <<~CPP.indent(2)
      #{scope_var}.const_set("#{name}", #{value});
    CPP
  end

  def self.define_includes(f, scope_var, names)
    raise "can't include a module on the global scope" unless scope_var
    Array.wrap(names).each do |name|
      module_var = build_scope_var('module', name)
      f.puts <<~CPP.indent(2)
        #{scope_var}.include_module(#{module_var});
      CPP
    end
  end

  def self.define_attributes(f, scope_var, attr_type, names)
    raise "can't define attributes on the global scope" unless scope_var
    scope_alias = extract_scope_alias(scope_var)
    singleton = 'singleton_' if attr_type.start_with? 'c'
    access_type = case attr_type
      when /_accessor$/ then ''
      when /_reader$/   then ', Rice::AttrAccess::Read'
      when /_writer$/   then ', Rice::AttrAccess::Write'
      end
    Array.wrap(names).each do |name|
      name, name_alias = name.split(ALIAS, 2)
      name_alias ||= name
      f.puts <<~CPP.indent(2)
        #{scope_var}.define_#{singleton}attr("#{name}", &#{scope_alias}::#{name_alias}#{access_type});
      CPP
    end
  end

  def self.define_methods(f, scope_var, names)
    scope_alias = extract_scope_alias(scope_var)
    names.each do |name, args|
      is_singleton, name = name.split('.', 2)
      name, is_singleton = is_singleton, false unless name
      raise "'#{is_singleton}' used instead of 'self'" if is_singleton && is_singleton != 'self'

      name, name_alias = name.split(ALIAS, 2)
      if name_alias
        is_static = case name_alias
          when 'static' then name_alias = name
          when STATIC   then name_alias.sub! STATIC, ''
          end
      else
        name_alias = name
      end
      name_alias = "#{scope_alias}::#{name_alias}" if scope_var && name_alias.exclude?('::')
      function_type = !scope_var ? 'global_function' : ('singleton_function' if is_singleton)
      function_type ||= is_static ? 'function' : 'method'
      if scope_var && !is_singleton && !is_static && name == 'initialize' && name_alias == scope_alias
        args_types, args_defaults = extract_types_and_defaults(args)
        args_types = ", #{args_types}" if args_types
        f.puts <<~CPP.indent(2)
          #{scope_var}.define_constructor(Rice::Constructor<#{scope_alias}#{args_types}>(#{args_defaults}));
        CPP
      else
        case args
        when Array
          args_defaults = args.map{ |arg| wrap_arg(arg) }.join(', ') if args.present?
        when Hash
          return_type, args = args.first
          args_types, args_defaults = extract_types_and_defaults(args)
          is_typedef = true
        when String
          is_lambda = true
        end
        args_defaults = ", #{args_defaults}" if args_defaults
        if is_typedef
          @i ||= 0
          typedef_alias = "rb_#{name_alias.full_underscore}__#{@i += 1}__"
          f.puts <<~CPP.indent(2)
            typedef #{return_type} (#{scope_alias}::*#{typedef_alias})(#{args_types});
          CPP
          definition = "#{typedef_alias}(&#{name_alias})#{args_defaults}"
        else
          definition = is_lambda ? args.strip : "&#{name_alias}#{args_defaults}"
        end
        dot = '.' if scope_var
        f.puts <<~CPP.indent(2)
          #{scope_var}#{dot}define_#{function_type}("#{name}", #{definition});
        CPP
      end
    end
  end

  def self.build_scope_var(scope_type, scope_alias)
    "rb_#{scope_type[0]}#{scope_alias.tr(' ', '').gsub('::', '_dc_').gsub('<', '_lt_').gsub(',', '_c_').gsub('>', '_gt_')}"
  end

  def self.extract_full_scope_alias(parent_var, scope_name)
    parent_alias = extract_scope_alias(parent_var)
    parent_var ? "#{parent_alias}::#{scope_name}" : scope_name
  end

  def self.extract_scope_alias(scope_var)
    scope_var.match(/^rb_[mc](\w+)$/)[1].gsub('_dc_', '::').gsub('_lt_', '<').gsub('_c_', ',').gsub('_gt_', '>') if scope_var
  end

  def self.extract_types_and_defaults(args)
    case args
    when Array, nil
      args = Array.wrap(args)
      case args.first
      when Array
        args.each_with_object([[], []]) do |arg, (types, defaults)|
          raise "invalid args [#{args}]" if !arg.is_a?(Array) || arg.size != 2
          types << arg.first; defaults << wrap_arg(arg.last)
        end
      when String
        raise "invalid types [#{args.map(&:class)}]" unless args.all?{ |arg| arg.is_a? String }
        [args, nil]
      end&.map{ |a| a.join(', ') if a.present? }
    else
      raise "invalid args type [#{args.class}]"
    end
  end

  def self.wrap_arg(arg)
    arg.sub(/^([a-zA-Z]\w*)( = )?/, 'Rice::Arg("\1")\2')
  end
end
