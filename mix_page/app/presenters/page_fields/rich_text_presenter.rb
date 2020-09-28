module PageFields
  class RichTextPresenter < TextPresenter
    def html_options
      super.merge! escape: false
    end

    def pretty_blank
      p_{ super }
    end
  end
end
