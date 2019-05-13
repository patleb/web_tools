Rails::Application.class_eval do
  def all_rake_tasks
    @_all_rake_tasks ||= begin
      Rake::TaskManager.record_task_metadata = true
      Rails.application.load_tasks
      tasks = Rake.application.instance_variable_get('@tasks')
      unless ExtRake.config.keep_install_migrations
        tasks.each do |t|
          if (task_name = t.first).end_with? ':install:migrations'
            tasks.delete(task_name)
          end
        end
      end
      tasks
    end
  end
end
