ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'minitest/ext_rails'
require 'minitest/mix_user'
require 'minitest/mix_file'
require 'minitest/mix_log'
