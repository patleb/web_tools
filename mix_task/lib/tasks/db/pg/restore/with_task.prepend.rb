module Db::Pg::Restore::WithTask
  def post_restore_environment
    super
    Task.where(state: :running).update_all(state: :unknown)
  end
end
