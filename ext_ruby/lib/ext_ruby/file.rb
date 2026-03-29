class File
  def self.each_line(path, first: nil, scrub: nil, chomp: nil, present: nil)
    i = 0
    if (path = path.to_s).end_with? '.gz'
      IO.popen("unpigz -c #{path}", 'rb') do |io|
        until io.eof?
          line = io.gets || ''
          line.scrub!(scrub) if scrub
          next if present && line.blank?
          line.chomp! if chomp
          yield(line, i) unless i == 0 && first == false
          break if first
          i += 1
        end
      end
    else
      File.foreach(path, chomp: chomp) do |line|
        line.scrub!(scrub) if scrub
        next if present && line.blank?
        yield(line, i) unless i == 0 && first == false
        break if first
        i += 1
      end
    end
  end
end
