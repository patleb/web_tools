module Sh::Process
  def kill(name, sudo: false, signal: nil, flags: '-o')
    %{#{'sudo' if sudo} bash -c 'process_pid=$(pgrep #{name} #{flags}); if [[ ! -z "$process_pid" ]]; then kill #{signal} $process_pid; fi'}
  end

  def pid(name, flags: '-o')
    "pgrep #{name} #{flags}"
  end
end
