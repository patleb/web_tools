class LogMessagePolicy < DeployerReadonlyPolicy
  def show?
    false
  end
end
