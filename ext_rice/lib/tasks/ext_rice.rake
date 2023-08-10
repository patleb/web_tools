require_relative './ext_rice/compiler'

namespace :rice do
  desc 'build c++ extension'
  task :build => :environment do
    compiler = ExtRice::Compiler.new
    compiler.run(compile: false)
  end

  desc 'compile c++ extension'
  task :compile => :environment do
    compiler = ExtRice::Compiler.new
    compiler.run
  end
end
