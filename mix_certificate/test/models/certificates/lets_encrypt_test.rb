require './test/test_helper'

class AcmeMock
  attr_reader :kid, :status, :token, :file_content, :certificate

  def initialize(status = 'valid')
    @status = status
    @kid = 'kid'
    @token = SecureRandom.hex(16)
    @file_content = SecureRandom.hex(64)
    @certificate = SecureRandom.hex(64)
  end

  def as_self(...)
    self
  end
  alias_method :new_account, :as_self
  alias_method :new_order, :as_self
  alias_method :http, :as_self
  alias_method :revoke, :as_self

  def do_nothing(...)
  end
  alias_method :request_validation, :do_nothing
  alias_method :initialize_account, :do_nothing
  alias_method :finalize, :do_nothing

  def authorizations
    [self]
  end
end

Certificates::LetsEncrypt.class_eval do
  def acme
    @acme ||= AcmeMock.new
  end
end

$now = Time.current

Time.class_eval do
  class << self
    let_stub :current, :frozen_time do
      $now
    end
  end
end

class Certificates::LetsEncryptTest < ActiveSupport::TestCase
  let(:frozen_time){ true }

  test '.create_or_renew, .find_current!, .find_by_token!, #revoke' do
    certificate = Certificates::LetsEncrypt.create_or_renew
    assert_equal({
      id: 'localhost/.well-known/acme-challenge',
      type: 'Certificates::LetsEncrypt',
      token: certificate.acme.token,
      challenge: certificate.acme.file_content,
      email: 'admin@email.example.com',
      kid: 'kid',
    }, certificate.attributes_hash.except(:expires_at, :created_at, :updated_at, :key, :crt, :json_data))
    assert_in_epsilon 90.days.from_now.to_i, certificate.expires_at.to_i
    assert_equal certificate.acme.certificate, certificate.decrypted(:crt)

    current = Certificates::LetsEncrypt.find_current!
    assert_equal certificate, current

    current.revoke
    assert_in_epsilon $now.to_i, current.expires_at.to_i

    record = Certificates::LetsEncrypt.select(:challenge).find_by_token! certificate.token
    assert_equal certificate.acme.file_content, record.challenge
  end
end
