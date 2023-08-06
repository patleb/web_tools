require_relative './ext_rice/compiler'

namespace :rice do
  desc 'compile c++'
  task :compile, [:skip_numo] => :environment do |t, args|
    numo = !flag_on?(args, :skip_numo)
    compiler = ExtRice::Compiler.new
    compiler.run(numo)
  end
end
