namespace :shakapacker do
  namespace :symlinks do
    desc 'update symlinks'
    task :update do
      require 'ext_shakapacker/shakapacker'
    end
  end
end

if Rake::Task.task_defined? 'assets:precompile'
  Rake::Task['assets:precompile'].enhance ['yarn:install']
end
