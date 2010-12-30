#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module RequestsHelper

  def new_request?(request_count)
    'new_requests' if request_count > 0
  end

  def new_request_link(request_count)
    if request_count > 0
      # changed by star, delete the link to manage page
      # link_to t('new_requests', :count => @request_count), aspects_manage_path
      t('new_requests', :count => @request_count)
    end
  end
end
