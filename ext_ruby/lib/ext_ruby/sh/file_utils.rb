module Sh::FileUtils
  def sub(path, old, new, **options)
    sed_replace(path, old, new, **options)
  end

  def gsub(path, old, new, **options)
    sub(path, old, new, **options, global: true)
  end

  def delete_line(path, value, **options)
    sub(path, value, '', **options, ignore: true, no_newline: true)
  end

  def delete_lines(path, value, **options)
    delete_line(path, value, **options, global: true)
  end

  def escape_newlines(path, **options)
    gsub(path, /\r?\n/, "\\\\n", **options, ignore: true)
  end

  %i(
    sub
    gsub
    delete_line
    delete_lines
    escape_newlines
  ).each do |name|
    define_method :"#{name}!" do |*args, **options|
      send(name, *args, **options, inline: true)
    end
  end

  def concat(path, string, escape: true, unique: false)
    quote = escape ? "'" : '"'
    command = "echo #{quote}#{string}#{quote} >> #{path}"
    command = "grep -Fq #{quote}#{string}#{quote} #{path} || #{command}" if unique
    command
  end

  def escape_regex(value)
    value.is_a?(Regexp) ? value.source.escape_single_quotes : value.escape_single_quotes.escape_regex
  end

  private

  def sed_replace(path, old, new, sudo: false, escape: true, delimiter: '%', ignore: nil, no_newline: nil, **options)
    inline = 'i' if options[:inline]
    global = 'g' if options[:global]
    quote = "'"
    old = escape_regex(old)
    new = escape_regex(new)
    unless escape
      quote = '"'
      old.gsub!('\\$', '$')
      new.gsub!('\\$', '$')
    end
    old = "(\\n[^\\n]*#{old}[^\\n]*|[^\\n]*#{old}[^\\n]*\\n)" if no_newline
    if delimiter == '%' && (old.include?('%') || new.include?('%'))
      delimiter = '|$#;'.chars.find{ |char| old.exclude?(char) && new.exclude?(char) } || delimiter
    end
    sed = %{sed -rz#{inline} -- #{[quote, 's', delimiter, old , delimiter, new, delimiter, global, quote].join} #{path}}
    if ignore
      sed = "sudo #{sed}" if sudo
      sed
    else
      <<~SH.squish
        if grep -qP #{[quote, old, quote].join} "#{path}"; then
          #{'sudo' if sudo} #{sed};
        else
          echo 'file "#{path}" does not include "#{old}"' && exit 1;
        fi
      SH
    end
  end
end
