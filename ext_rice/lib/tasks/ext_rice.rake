require_relative './ext_rice/compiler'

task :no_ext do
  ENV['NO_EXT'] = 'true'
end

namespace! :rice do
  desc 'build c++ extension'
  task :build => [:no_ext, :environment] do
    compiler = ExtRice::Compiler.new
    compiler.run(compile: false)
  end

  desc 'compile c++ extension'
  task :compile => [:no_ext, :environment] do
    compiler = ExtRice::Compiler.new
    compiler.run
  end

  desc 'compile c++ test suite'
  task :test_suite, [:root] => [:no_ext, :environment] do |t, args|
    compiler = ExtRice::Compiler.new
    compiler.test_suite(**args)
  end

  desc 'compile c++ test extension'
  task :test_extension, [:root] => [:no_ext, :environment] do |t, args|
    compiler = ExtRice::Compiler.new
    compiler.test_extension(**args)
  end

  desc 'start cling console'
  task :cling => :environment do
    exec <<-CMD.squish
      cling -I#{Rice.dst_path} -l#{Rice.gems_config[:cling].join(' -l')} --nologo
    CMD
  end

  desc 'run gdb test file'
  task :gdb, [:file_or_id, :breakpoint] => :environment do |t, args|
    ENV['DEBUG'] = 'true'
    case (file = args[:file_or_id]&.strip).presence
    when nil
      raise "'file_or_id' is required"
    when /^-?\d+$/
      id = file.to_i
      unless (file = rice_test_files[id])
        raise "invalid id [#{id}]"
      end
    else
      unless rice_test_files.include? file
        raise "invalid file [#{file}]"
      end
    end
    unless (breakpoint = args[:breakpoint]&.strip).present?
      raise "'breakpoint' is required"
    end
    if ENV['GUI'] == 'true'
      exec "seergdb --run --bf #{breakpoint} $(rbenv which ruby) #{file}"
    else
      exec "gdb --tui -q -ex 'set breakpoint pending on' -ex 'b #{breakpoint}' -ex r --args $(rbenv which ruby) #{file}"
    end
  end

  namespace :gdb do
    desc 'run GUI for gdb test file'
    task :gui, [:file_or_id, :breakpoint] => :environment do |t, args|
      ENV['GUI'] = 'true'
      run_task 'rice:gdb', *args
    end

    desc 'list gdb test files (with ids)'
    task :list => :environment do
      rice_test_files.each_with_index do |file, i|
        puts "[#{i}] #{file}"
      end
    end
  end

  private

  def rice_test_files
    Rails.root.glob('{test,**/test}/**/*_test.rb').select_map do |pathname|
      next unless pathname.read.include? '< Rice::TestCase'
      pathname.relative_path_from(Rails.root).to_s
    end
  end
end
