module MakeMakefile
  def find_header!(header, *paths)
    abort "#{header} not found" unless find_header(header, *paths)
  end
end
