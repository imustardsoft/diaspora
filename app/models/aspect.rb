#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Aspect
  include MongoMapper::Document

  key :name,        String
  key :post_ids,    Array

  # by star adding this field and relationship to record all the user this aspect is in
  key :visible_user_ids, Array, :typecast => 'ObjectId'
  many :visible_users, :in => :visible_user_ids, :class_name => 'User'
    
  many :contacts, :foreign_key => 'aspect_ids', :class_name => 'Contact'
  many :posts,    :in => :post_ids, :class_name => 'Post'

  belongs_to :user, :class_name => 'User'

  validates_presence_of :name
  validates_length_of :name, :maximum => 20
  #validates_uniqueness_of :name, :scope => :user_id
  validates_uniqueness_of :name # by star, set the name of aspect is unique
  attr_accessible :name

  # by star, after the new aspect is save, should save current user in it
  # and self should been save in current user
  after_create :save_user_and_aspect_ids
  def save_user_and_aspect_ids
    self.visible_users << self.user
    self.save
    self.user.visible_aspects << self
    self.user.save
  end

  
  before_validation do
    name.strip!
  end
  
  timestamps!

  def to_s
    name
  end
  
  def person_objects
    person_ids = people.map{|x| x.person_id}
    Person.all(:id.in => person_ids)
  end

  def as_json(opts = {})
    {
      :aspect => {
        :name   => self.name,
        :people => self.people.each{|person| person.as_json},
        :posts  => self.posts.each {|post|   post.as_json  },
      }
    }
  end

end

