#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Contact
  include MongoMapper::Document

  key :pending, Boolean, :default => true

  key :user_id, ObjectId
  belongs_to :user
  validates_presence_of :user

  key :person_id, ObjectId
  belongs_to :person
  validates_presence_of :person
  
  # by star, notes the following line for the user and invite somebody again
  #validates_uniqueness_of :person_id, :scope => :user_id

  validate :not_contact_for_self

  key :aspect_ids, Array, :typecast => 'ObjectId'  
  many :aspects, :in => :aspect_ids, :class_name => 'Aspect'

  def find_aspects
    contacts = self.user.contacts(:person_id => self.person_id)
    aspects = []
    for contact in contacts
      aspects += contact.aspects
    end
    aspects
  end
  
  def dispatch_request
    request = self.generate_request
    self.user.push_to_people(request, [self.person])
    request
  end

  def generate_request
    Request.new(:from => self.user, :to => self.person)
  end

  private
  def not_contact_for_self
    if person.owner_id == user.id
      errors[:base] << 'Cannot create self-contact'
    end
  end
end
