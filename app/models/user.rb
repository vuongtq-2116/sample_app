class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze
  ATTR_PARAMS = %i(name email password password_confirmation).freeze
  attr_accessor :remember_token, :activation_token, :reset_token
  self.per_page = Settings.users.per_page
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name: :Relationship,
                                  foreign_key: :follower_id,
                                  dependent: :destroy
  has_many :passive_relationships, class_name: :Relationship,
                                  foreign_key: :followed_id,
                                  dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  before_save{email.downcase!}
  before_create :create_activation_digest
  validates :name, presence: true, length: {maximum: Settings.max_length_name}
  validates :email, presence: true,
                    length: {maximum: Settings.max_length_email},
                    format: {with: VALID_EMAIL_REGEX},
                    uniqueness: true
  has_secure_password
  validates :password, presence: true,
            length: {minimum: Settings.min_length_pwd}, allow_nil: true

  class << self
    def digest string
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
      BCrypt::Password.create string, cost: cost
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attribute :remember_digest, User.digest(remember_token)
  end

  def forget
    update_attribute :remember_digest, nil
  end

  def authenticated? attribute, token
    digest = send "#{attribute}_digest"
    return unless digest

    BCrypt::Password.new(digest).is_password?(token)
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns reset_digest: User.digest(reset_token),
                  reset_sent_at: Time.zone.now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < Settings.users.expire_time_reset_pass.hours.ago
  end

  def follow other_user
    following << other_user
  end

  def unfollow other_user
    following.delete other_user
  end

  def following? other_user
    following.include? other_user
  end

  def feed
    Micropost.by_authors following_ids << id
  end

  private

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
