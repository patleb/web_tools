module Sh::Process
  def kill(name, sudo: false, signal: nil)
    %{#{'sudo' if sudo} bash -c 'process_pid=$(pgrep #{name} -o); if [[ ! -z "$process_pid" ]]; then kill #{signal} $process_pid; fi'}
  end

  def pid(name)
    "pgrep #{name} -o"
  end
end
