Open3.class_eval do
  class << self
    let_stub :capture3, :dry_run do |*cmd|
      ($test.result ||= []).concat cmd
    end
  end
end

Db::Pg::Base.class_eval do
  protected

  let_stub :notify?, :dry_run do
    false
  end
end
