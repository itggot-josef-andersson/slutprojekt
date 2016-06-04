class Category
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  has n, :tickets
  has n, :answers

end