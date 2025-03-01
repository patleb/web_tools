module MakeMakefile
  def include_dir(dir)
    opt = "-I#{dir}".quote
    $INCFLAGS << " " << opt
  end

  def add_library(lib, *)
    dir_config(lib)
    lib = with_config(lib+'lib', lib)
    libs = append_library($libs, lib)
    $libs = libs
  end
end

def find_header(_header, *paths)
  paths.each do |path|
    MakeMakefile.include_dir(path)
  end
end

def have_library(lib, *)
  MakeMakefile.add_library(lib, *)
end
