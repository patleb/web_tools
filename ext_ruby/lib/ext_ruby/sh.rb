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
    sub(path, /\n#{sed_escape(value)}/, '', **options, commands: ':r;$!{N;br};')
  end

  def self.delete_lines(path, value, **options)
    delete_line(path, value, **options, global: true)
  end

  def self.escape_newlines(path, **options)
    gsub(path, /\r?\n/, "\\\\n", **options, commands: ':a;N;$!ba;')
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

  def self.sed_escape(value)
    value.is_a?(Regexp) ? to_regex(value) : to_non_regex(value)
  end

  private_class_method

  def self.sed_replace(path, old, new, **options)
    inline = 'i' if options[:inline]
    global = 'g' if options[:global]
    %{sed -r#{inline} -- '#{options[:commands]}s/#{sed_escape(old)}/#{sed_escape(new)}/#{global}' #{path}}
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
