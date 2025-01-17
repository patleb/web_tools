ENV['PYTHON'] = '/usr/bin/python3.8' if File.exist? '/usr/bin/python3.8'

require 'pycall'
require 'ext_rails/pycall/pyobject_wrapper'

require 'pycall/import'
include PyCall::Import
