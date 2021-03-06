namespace :task do
  require Rails.root.join('app/tasks/application_task.rb')
  Dir[Rails.root.join('app/tasks/**/*.rb')].each { |f| require f }

  ApplicationTask.descendants.each do |task_class|
    namespace(task_class::Install.rake_task_namespace) do
      task_class::Install.rake_tasks.each do |rake_task|
        desc("Invokes #{task_class}##{rake_task}")
        task(task_class::Install.rake_task_name(rake_task) => :environment) do
          task_class.new.public_send(rake_task)
        end
      end
    end
  end
end
