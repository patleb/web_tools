require_relative './test_case'

Open3.class_eval do
  class << self
    let_stub :capture3, :dry_run do |*cmd|
      if cmd.first.strip.end_with? ' --list'
        __super__(:capture3, *cmd)
      else
        ($test.result ||= []).concat cmd
      end
    end
  end
end

Db::Pg::Base.class_eval do
  protected

  let_stub :notify?, :dry_run do
    false
  end
end

Minitest.after_run do
  Test::MuchRecord._drop_all_partitions!
  FileUtils.rm_rf(Setting[:backup_dir])
end
