module Rake::Task::WithLog
  def puts_started(args)
    Log.task(name, args: args.to_h.merge(argv: ARGV.drop(1).except('--')).compact_blank)
    super
  end

  def puts_success(total)
    Log.task(name, time: total)
    super
  end

  def puts_failure(exception)
    Notice.deliver! Rescues::RakeError.new(exception, data: { task: name }), subject: name unless $rake_notice_delivered
    $rake_notice_delivered ||= true
    super
  end

  def reset_notice
    $rake_notice_delivered = false
  end
end

Rake::Task.prepend Rake::Task::WithLog
