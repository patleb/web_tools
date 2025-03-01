### NOTE
# echo 'set history save on' >> ~/.gdbinit
# DEBUG=1 rake:test_compile
# gdb -q tmp/rice/test/.../unittest
module Rice
  extend WithGems

  class InvalidChecksum < ::StandardError; end

  CHECKSUM = /^[\da-f]{64}$/
  RB_CONSTANT = /((::)?[A-Z]\w*)+/
  CPP_CONSTANT = /((::)?[a-zA-Z][\w <:>]*)+/
  ALIAS = / +\| +/
  INHERIT = / +< +/
  STATIC = /^static +/
  SCOPE_KEYWORDS = /^(module|class) +#{RB_CONSTANT}(#{ALIAS}#{CPP_CONSTANT})?(#{INHERIT}#{CPP_CONSTANT})?$/
  ENUM_KEYWORD = /^enum +#{RB_CONSTANT}(#{ALIAS}#{CPP_CONSTANT})?$/
  CONSTANT_KEYWORD = /^[A-Z_][A-Z\d_]+$/
  INCLUDES_KEYWORD = 'include'
  ATTRIBUTES_KEYWORDS = /^c?attr_(accessor|reader|writer)$/
  METHODS_KEYWORD = 'def'
  MEMORY_ACTIONS = { 'NO_COLLECT' => 'keepAlive()', 'AS_VALUE' => 'setValue()', 'NO_DELETE' => 'takeOwnership()' }

  def self.require_ext
    require bin_path if require_ext?
  end

  def self.require_ext?
    return @require_ext if defined? @require_ext
    @require_ext = !ENV['NO_EXT'] && bin_path.exist?
  end

  class << self
    delegate :target, :target_path, :bin_path, :tmp_path, :checksum_path, :mkmf_path, :executable?, to: 'ExtRice.config'
  end

  def self.create_makefile(cflags: nil, libs: nil, vpaths: nil, dry_run: false)
    copy_files
    require_numo unless ENV['NO_NUMO']
    libraries, makefile = gems_config.values_at(:libraries, :makefile)
    libraries.each do |name|
      abort "#{name} not found" unless have_library(name)
    end
    yield(dst_path) if block_given?
    create_init_file unless executable?
    unless dry_run
      $CXXFLAGS += " -std=c++17 $(optflags)" # -O3 -ffast-math -fno-associative-math
      $CXXFLAGS += " #{makefile[:cflags]}" if makefile[:cflags].present?
      $CXXFLAGS += " #{cflags}" if cflags
      $CXXFLAGS += " -O0" if ENV['DEBUG']
      $libs += " #{makefile[:libs]}" if makefile[:libs].present?
      $libs += " #{libs}" if libs
      $srcs = Dir["#{dst_path}/**/*.{c,cc,cpp}"]
      $objs = $srcs.map{ |v| v.sub(/c+p*$/, "o") }
      $VPATH.concat(Array.wrap(makefile[:vpaths]).map(&:to_s))
      $VPATH.concat(Array.wrap(vpaths).map(&:to_s))
      if executable?
        MakeMakefile.create_makefile(target, dst_path.to_s) do |conf|
          conf << "\n"
          conf << "#{target}: $(OBJS)"
          conf << "\t$(ECHO) linking executable #{target}"
          conf << "\t-$(Q)$(RM) $(@)"
          conf << "\t$(Q) $(CXX) -o $@ $(OBJS) $(LIBPATH) $(LOCAL_LIBS) $(LIBS)"
          conf << "\n"
        end
      else
        MakeMakefile.create_makefile(target, dst_path.to_s)
      end
    end
  end

  def self.require_numo
    require "numo/narray"
    numo = File.join(Gem.loaded_specs["numo-narray"].require_path, "numo")
    find_header! "numo/narray.h", numo
    find_header! "numo/numo.hpp", dst_path
  end

  def self.write_checksum
    checksum_path.write(checksum)
  end

  def self.checksum_changed?
    checksum_was != checksum
  end

  def self.checksum
    @checksum_sum ||= begin
      sum = `cd #{tmp_path} && tar --mtime='1970-01-01' --exclude='*.o' -cf - src #{mkmf_path.basename}/Makefile | sha256sum | awk '{ print $1 }'`.strip
      raise InvalidChecksum unless sum.match? CHECKSUM
      sum
    end
  end

  def self.checksum_was
    if checksum_path.exist?
      sum = checksum_path.read
      raise InvalidChecksum unless sum.match? CHECKSUM
      sum
    end
  end

  def self.create_init_file
    headers, hooks = gems_config.values_at(:headers, :hooks)
    dst_path.join("#{target}.cpp").open('w') do |f|
      f.puts <<~CPP
        #{headers.map{ |header| %{#include "#{header.strip}"} }.join("\n")}
        #{hooks[:before_all].strip}
        #include "all.hpp"
        #{hooks[:after_all].strip}
        using namespace Rice;

        extern "C"
        void Init_#{target}() {
          #{hooks[:before_init].strip}
      CPP
      define_properties(f, nil, gems_config[:defs])
      f.puts <<~CPP
          #{hooks[:after_init].strip}
        }
      CPP
    end
  end

  def self.ext_cpp_body
    started = false
    ExtRice.config.root.join('test/fixtures/files/ext.cpp').readlines.each_with_object([]) do |line, lines|
      if !started && line.start_with?("void Init_ext() {")
        started = true
      elsif started
        break lines if line.start_with? '}'
        lines << line
      end
    end.join
  end

  # TODO multi constructors, registry, exception, iterator, director, stl define_(vector|map|...) etc.
  def self.define_properties(f, parent_var, hash)
    hash.each do |keyword, body|
      case keyword
      when SCOPE_KEYWORDS
        define_self(f, parent_var, keyword, body)
      when ENUM_KEYWORD
        define_enum(f, parent_var, keyword, body)
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
        #{class_type} #{scope_var} = define_class_under#{cpp_class}(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.squish.indent(2)
        #{class_type} #{scope_var} = define_class#{cpp_class}("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_module(f, parent_var, scope_name)
    scope_alias = extract_full_scope_alias(parent_var, scope_name)
    scope_var = build_scope_var('module', scope_alias)
    if parent_var
      f.puts <<~CPP.indent(2)
        Module #{scope_var} = define_module_under(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.indent(2)
        Module #{scope_var} = define_module("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_enum(f, parent_var, name, values)
    name, name_alias = name.split(/ +/, 2).last.split(ALIAS, 2)
    name_alias ||= name
    enum_var = build_scope_var('enum', name_alias)
    if parent_var
      f.puts <<~CPP.indent(2)
        Enum<#{name_alias}> #{enum_var} = define_enum_under<#{name_alias}>("#{name}", #{parent_var});
      CPP
    else
      f.puts <<~CPP.indent(2)
        Enum<#{name_alias}> #{enum_var} = define_enum<#{name_alias}>("#{name}");
      CPP
    end
    values.each do |value|
      value, value_alias = value.split(ALIAS, 2)
      value_alias ||= value
      f.puts <<~CPP.indent(2)
        #{enum_var}.define_value("#{value}", #{name_alias}::#{value_alias});
      CPP
    end
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
      when /_reader$/   then ', AttrAccess::Read'
      when /_writer$/   then ', AttrAccess::Write'
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
        args_defaults = ", #{args_defaults}" if args_defaults
        f.puts <<~CPP.indent(2)
          #{scope_var}.define_constructor(Constructor<#{scope_alias}#{args_types}>()#{args_defaults});
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
    name, action = arg.split('.')
    if (action = MEMORY_ACTIONS[action])
      name == 'return' ? "Return.#{action}" : name.sub(/^([a-zA-Z]\w*)( = )?/, %{Arg("\\1").#{action}\\2})
    else
      arg.sub(/^([a-zA-Z]\w*)( = )?/, 'Arg("\1")\2')
    end
  end
end
