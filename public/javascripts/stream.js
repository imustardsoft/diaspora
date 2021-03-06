/*   Copyright (c) 2010, Diaspora Inc.  This file is
 *   licensed under the Affero General Public License version 3 or later.  See
 *   the COPYRIGHT file.
 */

var Stream = {
  initialize: function() {
    //////////////////////////////by star, for like and dislike///////////////////////
    //for accept or ignore request
    $(".accept_invite").click(function(){
      var aspect_name = $(this).attr("aspect_name");
      var aspect_id = $(this).attr("aspect_id");
      var contact_id = $(this).attr("contact_id");
      var type = $(this).attr("type");
      var current = $(this).parent();
      $.ajax({
        type: "DELETE",
        url: "/requests/" + contact_id,
        data:{"type":type},
        success: function(data){
          current.remove();
          node = $("#aspect_nav").find("ul");
          nav = node.html();
          node.html("").append(nav+"<li><a href='/aspects/"+aspect_id+"'>"+aspect_name+"</a></li>")
          if (data == 0){
            $("#new_request_pane").html("");
            $(".new_requests").text("Home");
          }
          else{
            $(".new_requests").text("Home("+data+")");
            $("#new_request_pane").html("").append("<h1 class='new_request' style='text-align:center'>"+data+" new requests!</h1>")
          }
        }
      });
    });
    $(".ignore_invite").click(function(){
      var contact_id = $(this).attr("contact_id");
      var type = $(this).attr("type");
      var current = $(this).parent();
      $.ajax({
        type: "DELETE",
        url: "/requests/" + contact_id,
        data:{"type":type},
        success: function(data){
          current.remove();
          if (data == 0){
            $("#new_request_pane").html("");
            $(".new_requests").text("Home");
          }
          else{
            $(".new_requests").text("Home("+data+")");
            $("#new_request_pane").html("").append("<h1 class='new_request' style='text-align:center'>"+data+" new requests!</h1>")
          }
        }
      });
    });
    //for like or dislike
    $(".like_this, .cancel_like").live("click", function(){
      node = $(this).parent().next().find("span");
      var type = $(this).attr("class");
      if (type == "like_this"){
        $(this).addClass("hidden");
        $(this).next().removeClass("hidden");
      }
      else{
        $(this).prev().removeClass("hidden");
        $(this).addClass("hidden");
      }
      $.ajax({
        type: "PUT",
        data: {"type":$(this).attr("type")},
        url: "/p/" + $(this).attr("data"),
        success: function(data){
          node.html("").append(data);
        }
      });
    });

    $(".list").live("click", function(){
      $(this).parent().next().removeClass("hidden");
    });
    //////////////////////////////by star, for create event///////////////////////
    $(".yes_count").live("click", function(){
      $(this).parent().find(".no_disploy").addClass("hidden");
      $(this).parent().find(".maybe_disploy").addClass("hidden");
      $(this).parent().find(".yes_disploy").removeClass("hidden");
    })
    $(".no_count").live("click", function(){
      $(this).parent().find(".yes_disploy").addClass("hidden");
      $(this).parent().find(".maybe_disploy").addClass("hidden");
      $(this).parent().find(".no_disploy").removeClass("hidden");
    })
    $(".maybe_count").live("click", function(){
      $(this).parent().find(".yes_disploy").addClass("hidden");
      $(this).parent().find(".no_disploy").addClass("hidden");
      $(this).parent().find(".maybe_disploy").removeClass("hidden");
    })

    $(".event_form").live("click", function(){
      var status = $("#event_form").attr("class");
      if (status == "hidden"){
        $("#event_form").removeClass("hidden");
      }
      else{
        $("#event_form").addClass("hidden");
      }
    })
    $(".new_event").live('ajax:success', function(data, json, xhr) {
      json = $.parseJSON(json);
      WebSocketReceiver.addEventToStream(json['html']);
    });
    $(".new_event").live('ajax:failuer', function(data, json, xhr) {
      alert('failed to create event!');
    });

    $(".yes_event, .no_event, .maybe_event").live("click", function(){
      var id = $(this).parent().parent().attr("id");
      var type = $(this).attr("type");
      var node = $(this).parent();
      $.ajax({
        type: "PUT",
        url: "/events/" + id,
        data:{"type":type},
        success: function (data) {
          var count = ""
          if (type == "Yes"){
            count = node.parent().find(".yes_count");
          }
          if (type == "No"){
            count = node.parent().find(".no_count");
          }
          if (type == "Maybe"){
            count = node.parent().find(".maybe_count");
          }
          count.html("").append(data);
          node.html("").append("You selected <b>" + type+"</b><hr>");
        }
      });
    });
    ///////////// end //////////////////////////////////////////////////////
    
    
    var $stream = $(".stream");
    var $publisher = $("#publisher");

    $stream.not(".show").delegate("a.show_post_comments", "click", Stream.toggleComments);

    // publisher textarea reset
    $publisher.find("textarea").bind("blur", function(){ 
      $(this).css('height','42px');
    });

    // comment submit action
    $stream.delegate("a.comment_submit", "click", function(evt) {
      $(this).closest("form").children(".comment_box").attr("rows", 1);
    });

    $stream.delegate("textarea.comment_box", "keydown", function(e){
      if (e.shiftKey && e.keyCode === 13) {
        $(this).closest("form").submit();
      }
    });

    $stream.delegate("textarea.comment_box", "focus", function(evt) {
      var commentBox = $(this);
      commentBox
        .closest("form").find(".comment_submit").fadeIn(200);
    });

    $stream.delegate("textarea.comment_box", "blur", function(evt) {
      var commentBox = $(this);
      if (!commentBox.val()) {
        commentBox
          .attr('rows',2)
          .css('height','2.4em')
          .closest("form").find(".comment_submit").hide();
      }
    });

    // reshare button action
    $stream.delegate(".reshare_button", "click", function(evt) {
      evt.preventDefault();
      button = $(this)
      box = button.siblings(".reshare_box");
      if (box.length > 0) {
        button.toggleClass("active");
        box.toggle();
      }
    });

    $stream.delegate("a.video-link", "click", function(evt) {
      evt.preventDefault();

      var $this = $(this),
        container = document.createElement("div"),
        $container = $(container).attr("class", "video-container"),
        $videoContainer = $this.parent().siblings("div.video-container");

      if ($videoContainer.length > 0) {
        $videoContainer.slideUp('fast', function () {
          $videoContainer.detach();
        });
        return;
      }

      if ($("div.video-container").length > 0) {
        $("div.video-container").slideUp("fast", function() {
          $(this).detach();
        });
      }

      if ($this.data("host") === "youtube.com") {
        $container.html(
          '<a href="//www.youtube.com/watch?v=' + $this.data("video-id") + '" target="_blank">Watch this video on Youtube</a><br />' +
            '<iframe class="youtube-player" type="text/html" src="http://www.youtube.com/embed/' + $this.data("video-id") + '"></iframe>'
          );
      } else {
        $container.html('Invalid videotype <i>' + $this.data("host") + '</i> (ID: ' + $this.data("video-id") + ')');
      }

      $container.hide()
        .insertAfter($this.parent())
        .slideDown('fast');

      $this.click(function() {
        $container.slideUp('fast', function() {
          $(this).detach();
        });
      });
    });

    $(".new_status_message").bind('ajax:success', function(data, json, xhr) {
      json = $.parseJSON(json);
      WebSocketReceiver.addPostToStream(json['post_id'], json['html']);
    });
    $(".new_status_message").bind('ajax:failure', function(data, html, xhr) {
      alert('failed to post message!');
    });

    $(".new_comment").live('ajax:success', function(data, json, xhr) {
      json = $.parseJSON(json);
      WebSocketReceiver.processComment(json['post_id'], json['comment_id'], json['html'], false);
    });
    $(".new_comment").live('ajax:failure', function(data, html, xhr) {
      alert('failed to post message!');
    });

    $(".delete").live('ajax:success', function(data, html, xhr) {
      $(this).parents(".message").fadeOut(150);
    });

  },

  toggleComments: function(evt) {
    evt.preventDefault();
    var $this = $(this),
      text = $this.html(),
      commentBlock = $this.closest("li").find("ul.comments", ".content"),
      commentBlockMore = $this.closest("li").find(".older_comments", ".content"),
      show = (text.indexOf("show") != -1);


    if( commentBlockMore.hasClass("inactive") ) {
      commentBlockMore.fadeIn(150, function(){
        commentBlockMore.removeClass("inactive");
        commentBlockMore.removeClass("hidden");
      });
    } else {
      if(commentBlock.hasClass("hidden")) {
        commentBlock.fadeIn(150);
      }else{
        commentBlock.hide();
      }
      commentBlock.toggleClass("hidden");
    }

    $this.html(text.replace((show) ? "show" : "hide", (show) ? "hide" : "show"));
  }
};

$(document).ready(Stream.initialize);
