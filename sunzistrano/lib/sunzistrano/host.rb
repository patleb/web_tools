module Host
  VIRTUAL  = 'sun:add_virtual_host'

  def self.domains
    @domains ||= constants.each_with_object({}.to_hwia) do |constant, domains|
      tag = const_get(constant)
      first, last = /#{tag}([-.:\w]+)?-start/, /#{tag}([-.:\w]+)?-end/
      list = host_file_lines
      list = list.select{ |line| true if (line.match?(first) .. line.match?(last)) }
      list = list.reject{ |line| line.blank? || line.start_with?('#') }
      next if list.empty?
      name = constant.to_s.underscore
      domains[name] = list.map{ |line| line.split(/\s+/).compact_blank.take(2).reverse }.to_h
    end
  end

  def self.host_file_lines
    Pathname.new('/etc/hosts').readlines
  end
  private_class_method :host_file_lines
end
