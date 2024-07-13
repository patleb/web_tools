# frozen_string_literal: true

module ActiveTask::Base::WithLog
  protected

  def puts_step(name)
    Log.task("+#{name}")
    super
  end

  def puts_cancel
    Log.task('-cancel')
    super
  end
end

ActiveTask::Base.prepend ActiveTask::Base::WithLog
