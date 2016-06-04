class Answer
  include DataMapper::Resource

  property :id, Serial
  property :question, String
  property :answer, String

  belongs_to :category
end