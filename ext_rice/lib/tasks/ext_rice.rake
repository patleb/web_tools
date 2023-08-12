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

  desc 'compile c++ test executable'
  task :test_compile, [:root, :scope] => [:no_require_ext, :environment] do |t, args|
    options = args.to_h.with_keyword_access
    compiler = ExtRice::Compiler.new
    compiler.test_compile(**options)
  end
end
