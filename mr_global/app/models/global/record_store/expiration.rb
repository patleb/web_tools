module Global::RecordStore::Expiration
  extend ActiveSupport::Concern

  included do
    scope :expired, -> {
      updated_at, expires_at = column(:updated_at), column(:expires_at)
      expirable.where((updated_at < past_expires_at).or((expires_at != nil).and expires_at < Time.current))
    }
    scope :ongoing, -> {
      updated_at, expires_at = column(:updated_at), column(:expires_at)
      expirable.where((updated_at > past_expires_at).and((expires_at == nil).or expires_at > Time.current))
    }
    scope :expirable, -> { where(expires: true) }
    scope :permanent, -> { where(expires: false) }

    validates :expires_at, date: { after: proc{ 1.second.from_now }, before: proc{ future_expires_at }, allow_blank: true }
  end

  class_methods do
    def past_expires_at(from: ::Time.current)
      expires_in.seconds.ago(from)
    end

    def future_expires_at(from: ::Time.current)
      expires_in.seconds.since(from)
    end

    def past_touch_at(from: ::Time.current)
      touch_in.seconds.ago(from)
    end

    def future_touch_at(from: ::Time.current)
      touch_in.seconds.since(from)
    end

    def expires_in
      MrGlobal.config.expires_in
    end

    def touch_in
      MrGlobal.config.touch_in
    end
  end

  def expirable?
    expires
  end

  def permanent?
    !expirable?
  end

  def expired?
    expirable? && (self.class.future_expires_at(from: updated_at).past? || expires_at&.past?)
  end

  def expired_touch?
    expirable? && self.class.future_touch_at(from: updated_at).past?
  end

  def ongoing?
    expirable? && self.class.future_expires_at(from: updated_at).future? && (expires_at.nil? || expires_at.future?)
  end

  def expires_in
    if expires_at
      (expires_at - Time.current).to_i
    elsif expires
      (self.class.future_expires_at(from: updated_at) - Time.current).to_i
    end
  end

  def expires_in=(value)
    if value && !@freeze_expires
      self.expires = true
      self.expires_at = value.seconds.from_now
    end
    value
  end

  def expires=(value)
    @freeze_expires = !value
    self.expires_at = nil unless value
    self[:expires] = value
  end

  def stale?
    destroyed? || changed?
  end

  def _sync(version)
    return self if new?

    _sync_stale_state(version)

    return self if destroyed?

    if changed?
      with_lock do
        update! data: yield
      rescue ActiveRecord::RecordNotFound
        destroyed!
      end
    end

    self
  end

  def _sync_stale_state(version)
    if expired?
      delete
    elsif expired_touch?
      destroyed! unless touch
    else
      self.version = version
    end

    self
  end
end
