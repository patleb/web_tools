# TODO https://gist.github.com/prepor/1758845

Minitest::Spec::DSL.class_eval do
  def xdescribe(desc, &block)
    # do nothing
  end
  alias_method :xcontext, :xdescribe

  def xit(...)
    # do nothing
  end
  alias_method :xshould, :xit
  alias_method :xtest, :xit

  def describe_for(desc, *additional_desc, &block)
    describe desc, *additional_desc do
      subject{ desc.new }
      instance_eval(&block)
    end
  end
end
