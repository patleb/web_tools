module Pathname::WithoutRaise
  def delete(raise_on_no_entry = true)
    raise_on_no_entry ? super() : _delete
  end

  def rmtree(raise_on_no_entry = true)
    raise_on_no_entry ? super() : _rmtree
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

  def _rmtree
    rmtree
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

  def self.executable(name)
    paths = ENV["PATH"].split(File::PATH_SEPARATOR).map{ |path| new(path).cleanpath }
    paths.find{ |path| path.join(name).executable? }&.join(name)
  end

  def mkdir_p
    FileUtils.mkdir_p(self) unless exist?
    self
  end

  def touch
    FileUtils.touch self
    self
  end
end
