module Rails::Engine::WithTask
  def load_tasks(app = self)
    return self if @tasks_loaded
    require 'rake'
    Rake::TaskManager.record_task_metadata = true
    super
    tasks = Rake.application.ivar('@tasks')
    unless ExtRails.config.keep_install_migrations
      tasks.each do |t|
        if (task_name = t.first).end_with? ':install:migrations', 'active_storage:install'
          tasks.delete(task_name)
        end
      end
    end
    @tasks_loaded = true
    self
  end

  protected

  def run_tasks_blocks(*)
    super
    paths["app/tasks"].existent.sort.each { |ext| load(ext) } if paths["app/tasks"]
  end
end

Rails::Engine.prepend Rails::Engine::WithTask
