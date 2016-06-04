class Post
  include DataMapper::Resource

  property :id, Serial
  property :text, Text
  property :created, DateTime, :default => lambda{ |p,s| DateTime.now}

  belongs_to :ticket
  belongs_to :user

end