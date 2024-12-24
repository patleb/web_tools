class TaskPolicy < ActionPolicy::Base
  def index?
    Task.allowed_tasks.present?
  end

  def edit?
    model? || record.allowed?
  end

  class Scope < Scope
    def resolve
      names = Task.allowed_tasks
      names.present? ? relation.where(name: names) : super
    end
  end
end
