class Ticket
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :description, Text
  property :created, DateTime, :default => lambda{ |p,s| DateTime.now}

  # The status of a ticket
  # unassigned -> the ticket is new and hasn't been assigned to an administrator
  # unseen     -> the ticket has one or more posts that has not been seen by an administrator
  # open       -> the ticket has been seen but not solved
  # closed     -> the ticket has been marked as solved
  property :status, String, :default => 'unassigned'

  belongs_to :category
  belongs_to :user
  belongs_to :admin_user, :required => false

  # Every ticket acts as a "thread" which can have posts
  has n, :posts

  # Returns true if the ticket has been assigned to an admin
  def assigned?
    self.admin_user != nil
  end

  # Returns true if the ticket is closed
  def closed?
    self.status == 'closed'
  end

  # Returns true if the ticket has new activity
  def new_activity?
    self.status == 'new' || self.status == 'unseen'
  end

end