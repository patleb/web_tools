# https://github.com/Shopify/bootsnap/issues/168
# https://stackoverflow.com/questions/52420489/get-vs-code-ide-debugging-of-apps-on-rails-5-2-to-work
if defined? Debugger
  require 'bootsnap'

  env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['ENV']
  development_mode = ['', nil, 'development'].include?(env)

  Bootsnap.setup(
    cache_dir: 'tmp/cache',
    development_mode: development_mode,
    load_path_cache: true,
    autoload_paths_cache: true,
    compile_cache_iseq: false,
    compile_cache_yaml: true
  )
else
  require 'bootsnap/setup'
end
