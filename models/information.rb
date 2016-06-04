class Information
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :text, Text
  property :uploaded, DateTime, :default => lambda{ |p,s| DateTime.now}

  belongs_to :user

end