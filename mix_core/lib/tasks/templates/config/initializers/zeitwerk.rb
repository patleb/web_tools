%w(libraries tasks).each do |directory|
  ActiveSupport::Dependencies.autoload_paths.delete("#{Rails.root}/app/#{directory}")
end
