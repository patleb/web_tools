module Sh::Psql
  def psql(command, url = nil, options = nil)
    psql_cmd = url ? 'psql' : 'cd /tmp && sudo -u postgres psql -d postgres'
    psql_options = "--quiet --tuples-only --no-align --echo-errors #{options}" # "-qtAb"
    command_end = ';' unless command.strip.end_with? ';'
    %{#{psql_cmd} #{psql_options} -c "#{command}#{command_end}" #{url}}
  end
end
