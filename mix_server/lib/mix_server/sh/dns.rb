module Sh::Dns
  def append_host(id, address, name, **options)
    <<~SH
   #{"if [[ #{options[:if]} ]]; then" if options[:if] }
        sudo sed -rzi -- "s/# #{id}-start.*# #{id}-end\\n//g" /etc/hosts
        echo '# #{id}-start' | sudo tee -a /etc/hosts
        echo "#{address}  #{name}" | sudo tee -a /etc/hosts
        echo '# #{id}-end' | sudo tee -a /etc/hosts
   #{"fi" if options[:if] }
    SH
  end
end
