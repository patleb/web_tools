MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/controller.rb', '066490ae54efc396b1a9c2c3bd9aaf6eba34e72f744bb3d4fe9d9afb82ce86df']}
MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/cursor.rb', 'd2c93d0993f0d3b06c3ed25cbe578fecbb7ac29eca2efb7cd65bd282b9fd4324']}
MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/engine.rb', 'f9c9d6bdf3e88fb661f202957cccbc06317a6b5c7a17638ab697a4a75ca76834']}
MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/page.rb', '3aabd8082517fab11f4867946a620bc7e13a46f801d0f0fcc632c6c72e2845ef']}
MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/portions/portion_at_cursor.rb', 'e8c59a0a163c3d7f5b1f20058ab90addda4e03eb8bd2361d962a7d9b30b1237c']}
MonkeyPatch.add{['geared_pagination', 'lib/geared_pagination/portions/portion_at_offset.rb', 'abe049f7c6eca2136ea7372ba17e303416c6bfb0232da89885489720953eec62']}

require 'active_support/deprecation'
require "geared_pagination/version"

module GearedPagination
  def self.rails_7_1?
    Rails.version >= "7.1.0" rescue false
  end

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new(VERSION, "GearedPagination")
  end
end

class GearedPagination::Engine < ::Rails::Engine
  require 'geared_pagination/recordset'
  require 'geared_pagination/headers'

  initializer "geared_pagination.deprecator" do |app|
    app.deprecators[:geared_pagination] = GearedPagination.deprecator
  end

  ActiveSupport.on_load(:action_controller, run_once: true) do
    require 'ext_rails/geared_pagination/controller'
    require 'ext_rails/geared_pagination/cursor/with_single_query'
    require 'ext_rails/geared_pagination/page/with_single_query'
    require 'ext_rails/geared_pagination/portions/portion_at_cursor/with_single_query'
    require 'ext_rails/geared_pagination/portions/portion_at_offset/with_single_query'
  end
end
