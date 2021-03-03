module TaskJobContext
  extend ActiveSupport::Concern

  included do
    fixtures :users

    let(:email_task){ Task.find('try:send_email') }
    let(:raise_task){ Task.find('try:raise_exception') }
    let(:notify){ true }

    around do |test|
      MixTask.with do |config|
        config.available_names = {
          'try:send_email' => 1,
          'try:raise_exception' => 2,
        }
        Rake::Task['task:create'].invoke!
        Task.all.each(&:update!.with(notify: notify))
        test.call
        Task.connection.exec_query("TRUNCATE TABLE #{Task.quoted_table_name}")
      end
    end
  end
end
