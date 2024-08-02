module Enumerable
  def html_map(&block)
    parent_context = eval 'self', block.binding
    parent_context.send(:h_, map(&block))
  end
end
