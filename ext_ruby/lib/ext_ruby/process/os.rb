module Process
  class UnsupportedOS < ::StandardError; end

  SUPPORTED_OS = %w(ubuntu centos)

  def self.os
    @os ||= if SUPPORTED_OS.include? os_release[:id]
      ActiveSupport::StringInquirer.new(os_release[:id])
    else
      raise UnsupportedOS
    end
  end

  def self.os_version
    @os_version ||= os && os_release[:version_id]
  end

  private

  def self.os_release
    @os_release ||= Pathname.new('/etc/os-release').readlines.each_with_object({}.with_indifferent_access) do |line, all|
      next if line.exclude?('=')
      key, value = line.split('=', 2).map{ |part| part.strip.delete_prefix('"').delete_suffix('"').downcase }
      all[key] = value
    end
  end
end
