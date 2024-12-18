require './test/test_helper'

class ActiveStorage::BlobTest < ActiveStorage::TestCase
  self.file_fixture_path = Gem.root('mix_file').join('test/fixtures/files').to_s

  let(:filename){ 'circle.png' }
  let(:key){ 'i1uq3fq2bepgpxutsyx64te1silp' }

  test '#find_or_create_by_uid!' do
    file = file_fixture(filename)
    data = file.open
    blob = ActiveStorage::Blob.find_or_create_by_uid! filename, data, key: key, service_name: 'test'
    assert_equal 452, blob.byte_size
    blob.optimize
    assert_equal 216, blob.byte_size
  end
end
