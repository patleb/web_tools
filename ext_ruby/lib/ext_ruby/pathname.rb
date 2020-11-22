require 'pathname'

module Pathname::WithoutRaise
  def delete(raise_on_exception = true)
    raise_on_exception ? super() : _delete
  end

  def symlink(origin, raise_on_exception = true)
    raise_on_exception ? _symlink!(origin) : _symlink(origin)
  end

  private

  def _delete
    delete
  rescue Errno::ENOENT
    # do nothing
  end

  def _symlink(origin)
    _symlink!(origin)
  rescue Errno::EEXIST
    # do nothing
  end

  def _symlink!(origin)
    File.symlink(origin, self)
    self
  end
end

class Pathname
  prepend self::WithoutRaise

  SYSTEM_BASENAMES = %w(. ..).freeze

  def normalized_entries(hidden: false)
    root = to_s
    list = entries.lazy
    list =
      if hidden
        list.reject{ |file| SYSTEM_BASENAMES.include? file.to_s }
      else
        list.reject{ |file| file.to_s.start_with? '.' }
      end
    list = list.map{ |file| file.expand_path(root) }
    if block_given?
      yield list
    else
      list.force
    end
  end
end
