class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :mail, String

  ## These two will not be here when we use Google authentication
  property :username, String
  property :password, BCryptHash
  ## -----

  property :type, Discriminator

  has n, :tickets
  has n, :posts

  # Returns true if user is an admin.
  def admin?
    self.is_a? AdminUser
  end
end

class AdminUser < User

end