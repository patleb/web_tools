ActionView::Template::Error.class_eval do
  alias_method :old_message, :message
  def message
    [old_message, "#{file_name}:#{line_number}"].concat(annoted_source_code).join("\n")
  end

  module WithInitializedLineNumber
    def initialize(template)
      super
      @line_number = begin
        regexp = /#{Regexp.escape File.basename(file_name)}:(\d+)/
        $1 if old_message =~ regexp || backtrace.find { |line| line =~ regexp }
      end
    end
  end
  prepend WithInitializedLineNumber
end
