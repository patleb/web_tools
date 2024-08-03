module Shakapacker::Helper
  def javascript_pack_tag!(...)
    return if Rails.env.test?
    javascript_pack_tag(...)
  end

  def stylesheet_pack_tag!(...)
    return if Rails.env.test?
    stylesheet_pack_tag(...)
  end
end
