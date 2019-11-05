module Sh::Psql
  def psql(command, url = nil, pg_options = nil)
    sudo = "cd /tmp && sudo -u postgres" if url.nil?
    pg_options = "--quiet --tuples-only --no-align --echo-errors #{pg_options}" # "-qtAb"
    cmd_end = ';' unless command.strip.end_with? ';'
    [sudo, 'psql', ('-d postgres' if url.nil?), pg_options, '-c', '"', command, cmd_end, '"', url].join(' ')
  end
end
