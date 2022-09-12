class TaskPolicy < ApplicationPolicy
  def index?
    Task.visible_tasks.any?
  end

  def export?
    false
  end

  def show?
    false
  end

  def new?
    false
  end

  def edit?
    record.visible?
  end

  def delete?
    false
  end

  class Scope < Scope
    def resolve
      super.where(name: Task.visible_tasks)
    end
  end
end
