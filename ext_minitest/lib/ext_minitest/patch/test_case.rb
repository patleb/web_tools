module Patch
  class TestCase < Minitest::Spec
    def self.test_reference(gem_name, *files, scope: nil)
      gem_name = gem_name.to_s
      const_candidate = :"#{gem_name.to_s.upcase}_FILES"
      if files.empty? && defined?(const_candidate)
        files = const_get(const_candidate)
      end
      files.each do |file|
        describe "gem '#{gem_name}'" do
          it "should be the same code as '#{file}'" do
            expected, actual = expected_code(gem_name, file, scope: scope), actual_code(gem_name, file)
            diff = Diffy::Diff.new(expected, actual)
            assert expected == actual, diff.to_s(:color)
          end
        end
      end
    end

    def expected_code(gem_name, file, scope: nil)
      Pathname.new("test/patches/#{scope}/#{gem_name}/#{file}").expand_path.read
    end

    def actual_code(gem_name, file)
      spec = Bundler.load.specs.find{ |s| s.name == gem_name }
      Pathname.new("#{spec.full_gem_path}/#{file}").expand_path.read
    end
  end
end
