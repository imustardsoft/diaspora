#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Event
  include MongoMapper::Document

  timestamps!

  key :content, String
  key :location, String

  key :from_date, String
  key :from_time, String
  key :to_date, String
  key :to_time, String

  key :aspect_id, ObjectId
  key :yes_user_ids, Array, :typecast => 'ObjectId'
  key :no_user_ids, Array, :typecast => 'ObjectId'
  key :maybe_user_ids, Array, :typecast => 'ObjectId'
  
  belongs_to :user, :class_name => 'User'
  belongs_to :aspect, :class_name => 'Aspect'

  many :yes_users, :in => :yes_user_ids, :class_name => 'User'
  many :no_users, :in => :no_user_ids, :class_name => 'User'
  many :maybe_users, :in => :maybe_user_ids, :class_name => 'User'

  validates_presence_of :content
end

