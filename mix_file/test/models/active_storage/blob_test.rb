require './test/rails_helper'

class ActiveStorage::BlobTest < ActiveStorage::TestCase
  self.file_fixture_path = Gem.root('mix_file').join('test/fixtures/files').to_s

  let(:key){ 'i1uq3fq2bepgpxutsyx64te1silp' }

  it 'should optimize file size' do
    file = file_fixture('circle.png')
    blob = ActiveStorage::Blob.create_and_upload! io: file.open, key: key, filename: 'circle.png', service_name: 'test'
    assert_equal 452, blob.byte_size
    blob.optimize
    assert_equal 214, blob.byte_size
  end
end
