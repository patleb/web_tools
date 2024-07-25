require './test/spec_helper'

class PathnameTest < Minitest::TestCase
  let(:base_dir){ Pathname.new('./tmp/test/pathname') }

  test '#mkdir_p, #touch, #symlink, #delete, #rmtree' do
    base_dir.mkdir_p

    path = base_dir.join('touch')
    refute path.exist?
    path.touch
    assert path.exist?

    rel_path = path.relative_path_from(base_dir)
    link = base_dir.join('touch.link')
    link.symlink(rel_path)
    assert link.exist?
    assert link.symlink?
    assert_raises Errno::EEXIST do
      link.symlink(rel_path)
    end
    link.symlink(rel_path, false)

    path.delete
    refute path.exist?
    refute link.exist?
    link.delete
    assert_raises Errno::ENOENT do
      path.delete
    end
    path.delete(false)

    base_dir.rmtree
  end
end
