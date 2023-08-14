require_relative './ext_rice/compiler'

task :no_require_ext do
  ENV['NO_REQUIRE_EXT'] = true
end

namespace :rice do
  desc 'build c++ extension'
  task :build => [:no_require_ext, :environment] do
    compiler = ExtRice::Compiler.new
    compiler.run(compile: false)
  end

  desc 'compile c++ extension'
  task :compile => [:no_require_ext, :environment] do
    compiler = ExtRice::Compiler.new
    compiler.run
  end

  desc 'compile c++ test suite'
  task :test_suite, [:root] => [:no_require_ext, :environment] do |t, args|
    compiler = ExtRice::Compiler.new
    compiler.test_suite(**args)
  end

  desc 'compile c++ test extension'
  task :test_extension, [:root] => [:no_require_ext, :environment] do |t, args|
    compiler = ExtRice::Compiler.new
    compiler.test_extension(**args)
  end
end
