Minitest::UnexpectedError.class_eval do
  alias_method :old_message, :message
  def message
    old_message.lines(chomp: true).first(1).concat(backtrace).join("\n")
  end
end
