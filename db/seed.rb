class Seeder

  def self.seed!
    AdminUser.create :name => 'Josef Andersson Engman', :username => 'josef', :password => 'mypass123', :mail => 'josefandman@gmail.com'
    User.create :name => 'Adam Rohdell', :username => 'adam', :password => 'kappaross', :mail => 'adamisgey@gmail.com'

    Category.create :name => 'Användarnamn'
    Category.create :name => 'Dator'
    Category.create :name => 'Inloggning'
    Category.create :name => 'Email'
    Category.create :name => 'Övrigt'

    Information.create :title => 'Foxes brann ner', :text => 'Eftersom våran "älskade" restaurang har brunnit ner så måste vi tyvärr äta på donken.', :uploaded => 'Mon Apr 11 2016 21:55:23 GMT+0200', :user => User.first
    Information.create :title => 'Erkänner nederlag', :text => 'Det är med en kniv i hjärtat som jag medjer att <a href="http://beeg.com/">Josef</a> trots allt är aningen bättre än mig på diverse grejer. Jag är ledsen att jag gav upp så enkelt. PS. me is gey.', :uploaded => 'Mon Apr 11 2016 22:03:01 GMT+0200', :user => User.last
  end

end