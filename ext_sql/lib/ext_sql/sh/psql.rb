module Sh::Psql
  def psql(command, url = nil, pg_options = nil)
    sudo = "sudo -u postgres" if url.nil?
    pg_options = "--quiet --tuples-only --no-align --echo-errors #{pg_options}" # "-qtAb"
    cmd_end = ';' unless command.strip.end_with? ';'
    url = "'#{url}'" unless sudo
    %{cd /tmp && #{sudo} psql #{'-d postgres' if sudo} #{pg_options} -c "#{command}#{cmd_end}" #{url} && cd - || cd -}
  end
end
