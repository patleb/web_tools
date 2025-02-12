require "ext_rice"
require "mkmf-rice"

Rice.create_makefile do |dst|
  # find_header! "numo/numo.hpp", dst
end
