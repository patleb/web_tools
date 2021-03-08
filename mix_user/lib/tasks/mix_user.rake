namespace :user do
  desc 'create user'
  task :create, [:email, :password, :role, :confirmed] => :environment do |t, args|
    attributes = { email: args[:email], password: args[:password], password_confirmation: args[:password], role: args[:role] }
    if flag_on? args, :confirmed
      User.create! attributes.merge(confirmed_at: Time.current)
    else
      User.create! attributes
    end
  end

  desc 'List policies with their actions'
  task :policies => :environment do
    parents, classes, modules = {}, {}, {}
    (Rails::Engine.subclasses.map(&:root) << Rails.root).map do |root|
      Dir[root.join('app', 'policies', '**', '*_policy.rb')].sort.each do |file|
        policy_name = file.gsub(/^.+\/app\/policies\//, '').sub(/\.rb/, '').camelize
        policy = policy_name.constantize
        Set.new(ApplicationPolicy.actions).merge(policy.actions).each do |action_check|
          owner_name = policy.instance_method(action_check).owner.name
          if owner_name != policy.name
            parents[policy_name] ||= Set.new
            parents[policy_name] << "  < #{owner_name}"
          end
          if owner_name.end_with? 'Policy'
            classes[owner_name] ||= Set.new
            classes[owner_name] << action_check.to_s
          else
            modules[owner_name] ||= Set.new
            modules[owner_name] << action_check.to_s
          end
        end
      end
    end
    [classes, modules].each do |policies|
      policies.sort.each do |policy, actions|
        puts policy
        if parents[policy]
          puts *parents[policy].to_a
        end
        actions.each do |action_check|
          puts action_check.to_s.indent(2)
        end
      end
    end
  end
end
