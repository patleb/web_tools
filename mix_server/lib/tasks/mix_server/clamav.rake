namespace :clamav do
  desc 'scan directories for viruses'
  task :scan => :environment do
    options = '--recursive --infected --detect-pua=yes --stdout --no-summary'
    paths = `sudo clamscan #{options} #{MixServer.config.clamscan_dirs.join(' ')}`.lines(chomp: true).select_map do |line|
      next unless line.end_with? ' FOUND'
      line.split(':', 2).first
    end
    Log.clamav(paths) if paths.any?
  end
end
