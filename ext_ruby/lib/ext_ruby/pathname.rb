require 'pathname'

module Pathname::WithoutRaise
  def delete(raise_on_no_entry = true)
    raise_on_no_entry ? super() : _delete
  end

  def symlink(origin, raise_on_exist = true)
    raise_on_exist ? _symlink!(origin) : _symlink(origin)
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
end
