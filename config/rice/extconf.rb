require "ext_rice"
require "mkmf-rice"

ExtRice.config.yml_path = ExtRice.config.yml_path.sub_ext('.private.yml')

Rice.create_makefile do |dst|
  # find_header! "numo/numo.hpp", dst
end
