#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class PostsController < ApplicationController
  skip_before_filter :set_contacts_notifications_and_status
  skip_before_filter :count_requests
  skip_before_filter :set_invites
  skip_before_filter :set_locale

  ################ by star##########################
  def update
    post = Post.find(params[:id])
    if params[:type] == "like"
      if post.like_users.include?current_user
        render :text => "exist"
      elsif post.dislike_users.include?current_user
        render :text => "exist"
      else
        post.like_users << current_user
        post.save
        render :text => post.like_users.count.to_s
      end
    else
      if post.dislike_users.include?current_user
        render :text => "exist"
      elsif post.like_users.include?current_user
        render :text => "exist"
      else
        post.dislike_users << current_user
        post.save
        render :text => post.dislike_users.count
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
