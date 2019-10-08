module Sh
  def self.bash(cmd, sudo: false, u: true)
    "tmp=$(mktemp) " \
      "&& chmod +x $tmp " \
      "&& echo -e '#{cmd.escape_single_quotes.escape_newlines}' > $tmp " \
      "&& #{'sudo' if sudo} bash -#{'u' if u}c \"$tmp\" " \
      "&& rm -f $tmp"
  end

  def self.sub(path, old, new, **options)
    sed_replace(path, old, new, **options)
  end

  def self.gsub(path, old, new, **options)
    sub(path, old, new, **options, global: true)
  end

  def self.delete_line(path, value, **options)
    sub(path, value, '', **options, ignore: true, no_newline: true)
  end

  def self.delete_lines(path, value, **options)
    delete_line(path, value, **options, global: true)
  end

  def self.escape_newlines(path, **options)
    gsub(path, /\r?\n/, "\\\\n", **options, ignore: true, commands: ':a;N;$!ba;')
  end

  %i(
    sub
    gsub
    delete_line
    delete_lines
    escape_newlines
  ).each do |name|
    define_singleton_method :"#{name}!" do |*args, **options|
      send(name, *args, **options, inline: true)
    end
  end

  def self.concat(path, string, unique: false, bash: false)
    command = "echo '#{string}' >> #{path}"
    command = "grep -q -F '#{string}' #{path} || #{command}" if unique
    bash ? to_bash_command(command) : command
  end

  def self.escape_regex(value)
    value.is_a?(Regexp) ? to_regex(value) : to_non_regex(value)
  end

  private_class_method

  def self.sed_replace(path, old, new, escape: true, delimiter: '%', ignore: nil, no_newline: nil, commands: nil, **options)
    inline = 'i' if options[:inline]
    global = 'g' if options[:global]
    quote = "'"
    old_was = old
    old = escape_regex(old)
    new = escape_regex(new)
    unless escape
      quote = '"'
      commands&.gsub!('$', '\$')
      old.gsub!('\\$', '$')
      new.gsub!('\\$', '$')
    end
    old = "(\\n[^\\n]*#{old}[^\\n]*|[^\\n]*#{old}[^\\n]*\\n)" if no_newline
    if delimiter == '%' && (old.include?('%') || new.include?('%'))
      delimiter = '|$#;'.chars.find{ |char| old.exclude?(char) && new.exclude?(char) } || delimiter
    end
    sed = %{sed -rz#{inline} -- #{[quote, commands, 's', delimiter, old , delimiter, new, delimiter, global, quote].join} #{path}}
    if ignore
      sed
    else
      <<~SH.squish
        if grep -qP #{[quote, old, quote].join} "#{path}"; then
          #{sed};
        else
          echo 'file "#{path}" does not include "#{old_was.is_a?(Regexp) ? old_was.source : old_was}"' && exit 1;
        fi
      SH
    end
  end

  def self.to_regex(regex)
    regex.source.escape_single_quotes
  end

  def self.to_non_regex(string)
    string.escape_single_quotes.escape_regex
  end

  def self.to_bash_command(command)
    "bash -c \"#{command}\""
  end
end
