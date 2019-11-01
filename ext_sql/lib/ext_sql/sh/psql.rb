module Sh::Psql
  def psql(command, url = nil, pg_options = nil)
    sudo = "sudo -u postgres psql -d postgres" if url.nil?
    pg_options = "--quiet --no-align --tuples-only --echo-errors #{pg_options}"
    cmd_end = ';' unless command.strip.end_with? ';'
    url = "'#{url}'" if url
    %{#{sudo} psql #{pg_options} -c "#{command}#{cmd_end}" #{url}}
  end
end
