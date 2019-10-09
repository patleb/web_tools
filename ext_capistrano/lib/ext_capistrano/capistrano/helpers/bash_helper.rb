module ExtCapistrano
  module BashHelper
    def execute_bash(inline_code, sudo: false, u: true)
      tmp_file = shared_path.join('tmp', 'bash', "tmp.#{SecureRandom.hex(8)}.sh")
      upload! StringIO.new(inline_code), tmp_file
      execute "chmod +x #{tmp_file} && #{'sudo' if sudo} bash -#{'u' if u}c #{tmp_file} && rm -f #{tmp_file}"
    end
  end
end
