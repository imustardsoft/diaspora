#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class HandleValidator < ActiveModel::Validator
  def validate(document)
    unless document.diaspora_handle == document.person.diaspora_handle
      document.errors[:base] << "Diaspora handle and person handle must match"
    end
  end
end

class Comment
  require File.join(Rails.root, 'lib/diaspora/web_socket')
  require File.join(Rails.root, 'lib/youtube_titles')
  include YoutubeTitles
  include MongoMapper::Document
  include ROXML
  include Diaspora::Webhooks
  include Encryptable
  include Diaspora::Socketable

  xml_reader :text
  xml_reader :diaspora_handle
  xml_reader :post_id
  xml_reader :_id

  key :text,      String
  key :tags,      Array #added by star, for index of database
  key :post_id,   ObjectId
  key :person_id, ObjectId
  key :diaspora_handle, String

  belongs_to :post,   :class_name => "Post"
  belongs_to :person, :class_name => "Person"

  validates_presence_of :text, :diaspora_handle, :post
  validates_with HandleValidator

  before_save do
    self.tags = self.text.split(" ") #added by star for index of database
    get_youtube_title text
  end

  timestamps!

  ############ by star#################
  def self.search(query)
    return [] if query.to_s.empty?
    query_tokens = query.to_s.strip.split(" ")
    full_query_text = Regexp.escape(query.to_s.strip)

    p = []

    query_tokens.each do |token|
      q = Regexp.escape(token.to_s.strip)
      p = self.all('tags' => /^#{q}/i, 'limit' => 30)
    end

    return p
  end
  ############### end ########################
  
  def notification_type(user, person)
    if self.post.diaspora_handle == user.diaspora_handle
      return "comment_on_post"
    else
      return false
    end
  end

  #ENCRYPTION

  xml_reader :creator_signature
  xml_reader :post_creator_signature

  key :creator_signature, String
  key :post_creator_signature, String

  def signable_accessors
    accessors = self.class.roxml_attrs.collect{|definition|
      definition.accessor}
    accessors.delete 'person'
    accessors.delete 'creator_signature'
    accessors.delete 'post_creator_signature'
    accessors
  end

  def signable_string
    signable_accessors.collect{|accessor|
      (self.send accessor.to_sym).to_s}.join ';'
  end

  def verify_post_creator_signature
    verify_signature(post_creator_signature, post.person)
  end

  def signature_valid?
    verify_signature(creator_signature, person)
  end

  def self.hash_from_post_ids post_ids
    hash = {}
    comments = self.on_posts(post_ids)
    post_ids.each do |id|
      hash[id] = []
    end
    comments.each do |comment|
      hash[comment.post_id] << comment
    end
    hash.each_value {|comments| comments.sort!{|c1, c2| c1.created_at <=> c2.created_at }}
    hash
  end


  scope :on_posts, lambda { |post_ids| 
    where(:post_id.in => post_ids)
  }
end
