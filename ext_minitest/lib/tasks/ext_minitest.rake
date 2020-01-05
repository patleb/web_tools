namespace :ext_minitest do
  desc 'setup ExtMinitest files'
  task :setup do
    src, dst = Gem.root('ext_minitest').join('lib/tasks/templates'), Rails.root

    ['test/rails_helper.rb', 'test/spec_helper.rb'].each do |file|
      cp src/file, dst/file
    end

    remove dst/'test/test_helper.rb' rescue nil
    keep   dst/'test/cassettes'
  end
end
