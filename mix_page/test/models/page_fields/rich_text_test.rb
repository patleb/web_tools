require './test/rails_helper'

class PageFields::RichTextTest < ActiveStorage::TestCase
  let(:text){ <<-HTML.strip_heredoc }
    <p><br></p>
    <div class="se-component se-image-container __se__float-none" contenteditable="false">
      <figure style="margin: 0px;">
        <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAAAwCAIAAAAuKetIAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5QkBEjki+7eexQAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAABOklEQVRo3u2Z3a3DIAyFSdUB2ABG8AjeICMyAxPACB4BJsAb0IdIVVXpVrnE+ZN83h35izEcy1Pv3dxZD3NzKYACKIACKIACKIACbNBzp+8yMzMbY6y11trbAJRSiKjWWkp5A3jvnXMA4L2/LgAzE1GMMef8zn7RwoCI8zwDgHBBuoRaayEERPyRnLUWEUMIrbUuJyOVPQCs+V8AIMsgAJBSQsT1NUfElJIUwGN718YYiWh9yNIqpZRLvANElHP+bNk17Z5z/hfzjgDLjTlQt1rr+QDM/HVj7h0oDzCcxJZYNXMfb9PwsyrlkbYCeO8H8hgOlD9CzrkBi7bYu0tcowDw2wL9ZYpWWo8jzNy5VkLN3Nl2epLaD5w10EyyC47jR8pppw3NYUP9pCsmBVAABVAABVAABVCA++oFpogjxay64l4AAAAASUVORK5CYII=" alt="" data-rotate="" data-rotatex="" data-rotatey="" data-size="," data-align="none" data-percentage="auto,auto" data-index="1" data-file-name="circle.png" data-file-size="452" data-origin="," style="">
      </figure>
    </div>
    <p><br></p>
  HTML
  let(:key){ 'i1uq3fq2bepgpxutsyx64te1silp' }
  let(:url){ <<-HTML.strip_heredoc }
    <div class="se-component se-image-container __se__float-none" contenteditable="false">
      <figure style="margin: 0px;">
        <img src="http://127.0.0.1:3333/storage-test/#{key[0..1]}/#{key[2..3]}/#{key}" alt="" data-rotate="" data-rotatex="" data-rotatey="" data-size="," data-align="none" data-percentage="auto,auto" data-index="1" data-file-name="circle.png" data-file-size="452" data-origin="," style="">
      </figure>
    </div>
  HTML

  around do |test|
    MixJob.with do |config|
      config.async = false
      MixPage.with do |config|
        config.available_templates = {
          'generic_multi' => 0,
          'home' => 10
        }
        config.max_image_size = 500.bytes
        test.call
      end
    end
  end

  it 'should replace base64 images with attachments' do
    template = PageTemplate.create! view: PageTemplate.available_views.keys.first
    field = template.page_fields.create! type: 'PageFields::RichText', name: 'page_texts'
    blob = ActiveStorage::Blob.create! key: key, filename: 'no_file.png', content_type: 'image/png', service_name: 'test', byte_size: 0, checksum: Digest::MD5.base64digest('')
    ActiveStorage::Attachment.create! name: 'images', record: field, blob: blob

    field.update! text_fr: text + url, text_en: text + text

    assert_equal 'ActiveStorage::AnalyzeJob', Job.dequeue.job_class
    assert_equal 'ActiveStorage::MirrorJob', Job.dequeue.job_class
    assert_equal 'ActiveStorage::AnalyzeJob', Job.dequeue.job_class
    assert_equal 'ActiveStorage::MirrorJob', Job.dequeue.job_class
    assert_nil Job.dequeue
    rich_text = PageFields::RichText.first
    assert_equal 2, rich_text.images_attachments.count
    assert_equal 2, rich_text.images_blobs.count
    assert_equal 1, rich_text.images_blobs.select_map(&:backup).count
    assert_equal 2, rich_text.text_en.scan(/#{ExtRails::Routes.url_for('/storage-test/')}/).size
    assert_equal 2, rich_text.text_fr.scan(/#{ExtRails::Routes.url_for('/storage-test/')}/).size
  end
end
