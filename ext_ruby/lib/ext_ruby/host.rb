module Host
  VAGRANT        = 'vagrant-hostmanager'
  SERVER         = 'cap:dns-set_hosts-server'
  HOSTNAME       = 'cap:dns-set_hosts-hostname'
  CLUSTER_MASTER = 'cap:dns-set_hosts-cluster_master'

  def self.domains
    @domains ||= constants.each_with_object({}.with_keyword_access) do |constant, memo|
      tag = const_get(constant)
      first, last = "#{tag}-start", "#{tag}-end"
      list = Pathname.new('/etc/hosts').readlines
      list.select!{ |line| true if (line.include?(first) .. line.include?(last)) }
      next if list.empty?
      memo[constant.to_s.underscore] = list[1..-2]
        .reject(&:blank?)
        .map(&:split)
        .map{ |(ip, name)| [name, ip] }
        .sort_by(&:first)
        .to_h
    end
  end
end
