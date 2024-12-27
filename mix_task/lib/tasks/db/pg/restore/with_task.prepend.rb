module Db::Pg::Restore::WithTask
  def post_restore_environment
    super
    Task.running.update_all(state: :unknown)
  end
end
