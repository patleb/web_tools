require 'pathname'

class Pathname
  SYSTEM_BASENAMES = %w(. ..).freeze

  def normalized_entries(hidden: false)
    root = to_s
    list = entries.lazy
    list =
      if hidden
        list.reject{ |file| SYSTEM_BASENAMES.include? file.to_s }
      else
        list.reject{ |file| file.to_s.start_with? '.' }
      end
    list = list.map{ |file| file.expand_path(root) }
    if block_given?
      yield list
    else
      list.force
    end
  end
end
