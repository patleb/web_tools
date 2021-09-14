namespace :clamav do
  desc 'scan directories for viruses'
  task :scan => :environment do
    options = '--recursive --infected --detect-pua=yes --stdout --no-summary'
    paths = `sudo clamscan #{options} #{MixServer.config.clamav_dirs.join(' ')}`.lines(chomp: true).select_map do |line|
      next unless line.end_with? ' FOUND'
      path = line.split(':', 2).first
      next if MixServer.config.clamav_false_positives.any?{ |fp| fp.is_a?(Regexp) ? path.match?(fp) : path == fp }
      path
    end
    Log.clamav(paths) if paths.any?
  end
end
