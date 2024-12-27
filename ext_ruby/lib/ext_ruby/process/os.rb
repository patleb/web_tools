module Process
  class UnsupportedOS < ::StandardError; end

  SUPPORTED_OS = %w(ubuntu linuxmint)

  def self.os
    @os ||= SUPPORTED_OS.include?(os_release[:id]) ? ActiveSupport::StringInquirer.new(os_release[:id]) : raise(UnsupportedOS)
  end

  def self.os_version
    @os_version ||= os && os_release[:version_id][/\d+(\.\d+)?/]&.to_f
  end

  def self.os_release
    @os_release ||= Pathname.new('/etc/os-release').readlines.each_with_object({}.to_hwka) do |line, all|
      next if line.exclude?('=')
      key, value = line.split('=', 2).map{ |part| part.strip.delete_prefix('"').delete_suffix('"').downcase }
      all[key] = value
    end.slice(:id, :version_id, :version_codename)
  end

  def self.os_kernel
    @os_kernel ||= os && Pathname.new('/proc/version').read[/\d+(\.\d+)?/]&.to_f
  end
end
