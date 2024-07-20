### References
# https://github.com/metaskills/minitest-spec-rails/blob/master/lib/minitest-spec-rails/parallelize.rb

module Minitest::Spec::DSL::SpecTests
end

module Kernel
  alias_method :describe_before_minitest_spec_constant_fix, :describe
  private :describe_before_minitest_spec_constant_fix
  def describe(*args, &block)
    cls = describe_before_minitest_spec_constant_fix(*args, &block)
    cls_const = "Test__#{cls.name.to_s.split(/\W/).reject(&:empty?).join('_'.freeze)}"
    if block.source_location
      source_path, line_num = block.source_location
      source_path = Pathname.new(File.expand_path(source_path)).relative_path_from(Rails.root).to_s
      source_path = source_path.split(/\W/).reject(&:empty?).join("_".freeze)
      cls_const += "__#{source_path}__#{line_num}"
    end
    cls_const += "_1" while Minitest::Spec::DSL::SpecTests.const_defined? cls_const
    Minitest::Spec::DSL::SpecTests.const_set cls_const, cls
    cls
  end
end
