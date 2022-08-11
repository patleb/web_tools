module Sunzistrano
  HELPER_PUBLIC = /^([\w.]+)\s*\(\)\s*\{\s*#\s*public\s*$/i

  Context.class_eval do
    def bash_scripts
      @bash_scripts ||= SortedSet.new(sun.scripts || [])
    end

    def bash_helpers
      @bash_helpers ||= begin
        files = []; role_helpers{ |file, root| files << root.join(CONFIG_PATH, file) }
        helpers = files.each_with_object([]) do |file, memo|
          Pathname.new(file).each_line do |line|
            name = line.match(HELPER_PUBLIC)&.captures&.first
            memo << name if name
          end
        end
        SortedSet.new(helpers)
      end
    end
  end
end
