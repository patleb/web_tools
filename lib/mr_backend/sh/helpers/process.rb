module Sh::Process
  def kill(name, pgrep_options = nil, signal: nil)
    <<-SH.squish
      sudo bash -c '
        process_pid=$(pgrep #{name} #{pgrep_options});
        if [[ ! -z "$process_pid" ]]; then
          kill #{"-#{signal}" if signal} $process_pid;
        fi
      '
    SH
  end
end
