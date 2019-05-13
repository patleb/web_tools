require_rel 'sh'

module Sh
  Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'sh/**/*.rb')].each do |file|
    name = File.basename(file, '.rb')
    extend const_get(name.camelize)
  end
end
