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
    event.yes_users << current_user if params[:type] == "Yes"
    event.no_users << current_user if params[:type] == "No"
    event.maybe_users << current_user if params[:type] == "Maybe"
    render :text => "ok" if event.save
    current_user.vote_events << event
    current_user.save
  end
  
  def index
    @aspects = current_user.visible_aspects
    @events = []
    for a in @aspects
      @events += a.events
    end
    @events = @events.paginate :page => params[:page], :per_page => 15, :order => 'created_at desc'
  end

  def show
    @event = Event.find(params[:id])
  end

  def destory
    
  end

end

