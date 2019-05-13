class MrRecipe::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/mr_recipe.rake'
  end
end
