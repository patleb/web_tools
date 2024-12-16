require './test/test_helper'

class PageFieldMarkdownTest < ActiveStorage::TestCase
  let(:markdown){ field.markdown }
  let(:field){ template.page_fields.create! type: 'PageFields::Html', name: 'list_texts' }
  let(:template){ PageTemplate.create! view: PageTemplate.available_views.keys.first }
  let(:blob) do
    ActiveStorage::Blob.create!(
      key: key,
      filename: 'no_file.png',
      content_type: 'image/png',
      service_name: 'test',
      byte_size: 0,
      checksum: Digest::MD5.base64digest(''),
      uid: uid
    )
  end
  let(:uid){ [Base64.strict_encode64('no_file.png'), Digest::SHA2.base64digest('')].join(',') }
  let(:key){ 'i1uq3fq2bepgpxutsyx64te1silp' }
  let(:text){ <<-MARKDOWN.strip_heredoc }
    # Title
    ![image.png](blob:#{blob.id})
  MARKDOWN
  let(:html){ <<-HTML.strip_heredoc }
    <h1>Title</h1>

    <p><img src="http://127.0.0.1:3333/storage_test/#{key[0..1]}/#{key[2..3]}/#{key}" alt="image.png"></p>
  HTML

  around do |test|
    MixJob.with do |config|
      config.async = false
      test.call
    end
  end

  test '#convert_to_html' do
    markdown.update! text_fr: text, text_en: text
    assert_equal 'ActiveStorage::OptimizeJob', Job.dequeue.job_class
    assert_equal 'ActiveStorage::MirrorJob', Job.dequeue.job_class
    assert_equal 'ActiveStorage::AnalyzeJob', Job.dequeue.job_class
    assert_nil Job.dequeue
    assert_equal html, markdown.page_field.text_fr
    assert_equal html, markdown.page_field.text_en
    assert_equal 1, markdown.images_attachments.count
    assert_equal 1, markdown.images_blobs.count
    assert_equal blob, ActiveStorage::Blob.find_or_create_by_uid!('no_file.png', StringIO.new(''))
    assert_equal 1, markdown.images_blobs.select_map(&:backup).count
  end
end
