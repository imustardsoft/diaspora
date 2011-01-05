#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class EventsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  respond_to :json, :only => :show
  
  def create
    @event = current_user.events.create(params[:event])
    respond_to do |format|
      format.js{ render :json => {:html => render_to_string(
                                     :partial => 'aspects/aspect_events',
                                     :locals => {
                                       :aspect => @event.aspect
                                      }
                                   )
                                  },
                                   :status => 201 }
      format.html{ respond_with @event, :status => 200 }
    end
  end

  def update
    event = Event.find(params[:id])
    count = 0
    if params[:type] == "Yes"
      event.yes_users << current_user
      count = event.yes_users.count
    elsif params[:type] == "No"
      event.no_users << current_user
      count = event.no_users.count
    else
      event.maybe_users << current_user
      count = event.maybe_users.count
    end
    event.save
    current_user.vote_events << event
    current_user.save
    render :text => count
  end
  
  def index
    @aspects = current_user.visible_aspects
    @events = []
    for a in @aspects
      @events += a.events
    end
    @events = @events.paginate :page => params[:page], :per_page => 15, :order => 'created_at desc'
  end

  def destory
    
  end

end

