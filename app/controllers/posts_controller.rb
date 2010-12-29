#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class PostsController < ApplicationController
#  skip_before_filter :set_contacts_notifications_and_status
#  skip_before_filter :count_requests
#  skip_before_filter :set_invites
#  skip_before_filter :set_locale
  before_filter :authenticate_user!
  ################ by star##########################
  def index
    @posts = Post.search(params[:q])
    @comments = Comment.search(params[:q])
  end

  def update
    post = Post.find(params[:id])
    if params[:type] == "like"
      count = post.like_users.count
      post.like_users << current_user
      post.save
      if count > 0
        render :text => "<a class='list'>I and " + count.to_s + " people like this post</a>"
      else
        render :text => "I like this post"
      end
    else
      post.like_user_ids.delete current_user.id
      post.save
      count = post.like_users.count
      if count > 0
        render :text => "<a class='list'>"+ count.to_s + " people like this post</a>"
      else
        render :text => ""
      end
    end
  end
  ################### end ###################################
  
  def show
    @post = Post.first(:id => params[:id], :public => true)

    if @post
      @landing_page = true
      @person = @post.person
      if @person.owner_id
        I18n.locale = @person.owner.language
        render "posts/#{@post.class.to_s.underscore}", :layout => true
      else
        flash[:error] = "that post does not exsist!"
        redirect_to root_url
      end
    else
      flash[:error] = "that post does not exsist!"
      redirect_to root_url
    end    
  end
end
