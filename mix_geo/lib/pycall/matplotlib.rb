require 'pycall'

Matplotlib = PyCall.import_module('matplotlib')

module Matplotlib
  Pyplot = PyCall.import_module('matplotlib.pyplot')
end
