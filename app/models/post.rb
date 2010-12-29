#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Post
  require File.join(Rails.root, 'lib/encryptable')
  require File.join(Rails.root, 'lib/diaspora/web_socket')
  include MongoMapper::Document
  include ApplicationHelper
  include ROXML
  include Diaspora::Webhooks

  xml_reader :_id
  xml_reader :diaspora_handle
  xml_reader :public
  xml_reader :created_at

  ################### by star ##############################
  key :like_user_ids, Array, :typecast => 'ObjectId'
  many :like_users, :in => :like_user_ids, :class_name => 'User'
  #key :dislike_user_ids, Array, :typecast => 'ObjectId'
  #many :dislike_users, :in => :dislike_user_ids, :class_name => 'User'
  #################### end #################################

  key :public, Boolean, :default => false

  key :diaspora_handle, String
  key :user_refs, Integer, :default => 0
  key :pending, Boolean, :default => false
  key :aspect_ids, Array, :typecast => 'ObjectId'

  many :comments, :class_name => 'Comment', :foreign_key => :post_id, :order => 'created_at ASC'
  many :aspects, :in => :aspect_ids, :class_name => 'Aspect'
  belongs_to :person, :class_name => 'Person'

  timestamps!

  cattr_reader :per_page
  @@per_page = 10

  before_destroy :propogate_retraction
  after_destroy :destroy_comments

  attr_accessible :user_refs
  
  def self.instantiate params
    new_post = self.new params.to_hash
    new_post.person = params[:person]
    new_post.aspect_ids = params[:aspect_ids]
    new_post.public = params[:public]
    new_post.pending = params[:pending]
    new_post.diaspora_handle = new_post.person.diaspora_handle
    new_post
  end

  def as_json(opts={})
    {
      :post => {
        :id     => self.id,
        :person => self.person.as_json,
      }
    }
  end

  def mutable?
    false
  end

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
  protected
  def destroy_comments
    comments.each{|c| c.destroy}
  end

  def propogate_retraction
    self.person.owner.retract(self)
  end
end

