module PageFields
  class Text < PageField
    default_scope{ rewhere(type: klass.name) }

    json_translate text: :string
  end
end
