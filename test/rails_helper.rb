ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'ext_minitest/rails_helper'
require 'minitest/ext_rails'
require 'minitest/mix_file'
require 'minitest/mix_log'
require 'minitest/mix_task'
require 'minitest/mix_template'
