module Sh::Psql
  def psql(command, url = nil, pg_options = nil)
    sudo = "sudo -u postgres" if url.nil?
    pg_options = "--quiet --no-align --tuples-only --echo-errors #{pg_options}"
    cmd_end = ';' unless command.strip.end_with? ';'
    %{#{sudo} psql #{'-d postgres' if sudo} #{pg_options} -c "#{command}#{cmd_end}" #{"'#{url}'" unless sudo}}
  end
end
