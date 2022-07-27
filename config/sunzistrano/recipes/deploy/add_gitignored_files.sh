desc 'Add necessary gitignored files'
sun.copy "$release_path/lib/web_tools/private.rb"
sun.copy "$release_path/Gemfile.lock"
sun.copy "$release_path/Gemfile.private"
sun.copy "$release_path/yarn.lock"
