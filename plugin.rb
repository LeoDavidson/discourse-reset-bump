# name: discourse-reset-bump
# about: Gives staff a quick button for resetting a topic's bump time to that of a particular post.
# version: 0.1
# authors: Leo Davidson
# url: https://github.com/leodavidson/discourse-reset-bump

# The comments above are not just comments. Discourse will parse them for the plugin name etc.

# Declare that one of the things in config/settings.yml turns the whole plugin on and off.
# Discourse uses this for the Enabled Y/N field. It's up to us to check it in our code as well.

enabled_site_setting :reset_bump_enabled

# after_initialize is a callback that happens after this ruby file has been loaded. I'm not sure
# if we NEED to do everything in after_initialize but it's the done thing, and may ensure we
# instantiate other objects after all the modifications have been done to them, not before.

after_initialize do

  # Isolate our plugin in a separate Rails Engine and namespace.
  # This helps avoid conflicts between e.g. two objects having the same names.

  module ::DiscourseResetBump
    class Engine < ::Rails::Engine
      engine_name "discourse_reset_bump"
      isolate_namespace DiscourseResetBump
    end
  end

  # A controller is how the client-side javascript code communicates with the sever-side
  # Ruby on Rails code. Once everything is hooked up, there will be a URL which results
  # in our controller being called, and returning something that might be displayed to
  # the user or consumed by client-side code (e.g. a success/failure indicator).
  # This is the best guide I could find, although it is about modifying Discourse itself
  # and not about writing plugins, so not everything is completely applicable:
  # https://meta.discourse.org/t/creating-routes-in-discourse-and-showing-data/48827

  require_dependency 'application_controller'
  class DiscourseResetBump::ResetBumpController < ::ApplicationController
    # As our functionality is only intended for "staff" users, we do server-side
    # checks to ensure we are called from a logged-on user, and that the user is staff.
    # You'll find other plugins and Discourse code using before_filter instead of
    # before_action. Both do the same thing in Rails 4.2, so we can use either. Rails 5.0
    # makes 'before_filter' deprecated and start causing warnings, and Rails 5.1 will remove
    # it entirely, so let's use the newer name from the start. We're on Rails 4.2 as of writing.
    # See: http://stackoverflow.com/questions/16519828/rails-4-before-filter-vs-before-action
    before_action :ensure_logged_in
    before_action :ensure_staff

    # The Admin::AdminController mentioned in "Creating Routes in Discourse and Showing Data"
    # is (at the time of writing) like ::ApplicationController but with the above two checks
    # built-in, and an "index" method that returns nothing. I'm not sure if we should use 
    # Admin::AdminController from a plugin (other plugins I looked at don't) and I only worked
    # out how to after I had already tested things, so I'm sticking with how it is. But here
    # is how you would use Admin::AdminController instead if you wanted to:
    #
    # require_dependency 'admin/admin_controller'
    # class DiscourseResetBump::ResetBumpController < Admin::AdminController
    #   ...then don't bother with the before_action lines, and the rest is then as it is now.

    # TODO: Should we have an index method that renders nothing like Admin::AdminController?
    #       What is the real purpose of it? Also, should we use Admin::AdminController itself?

    # Each method name corresponds to one of the Engine.routes.draw things below.
    # "bump" is our main method, and may end up being the only one we need.
    def bump

      # params[:post_id].to_i would return 0 if the param was missing, so this is a bit redundant
      # but a good habit for when zero is a valid input that we need to separate from a missing param.
      if (!params.has_key?(:post_id))
        return render_json_error("Parameter missing: post_id")
      end

      post_id = params[:post_id].to_i

      # There is never a post with id <= 0.
      if (post_id <= 0)
        return render_json_error("Parameter invalid: post_id")
      end

      # I'd like to wrap everything in a transaction so it is atomic...
      # ...but I don't understand Rails transactions well enough. :-) It's not super important in this case.
      # I'd be nice if we update the time, but then fail to update the log, that we'd rollback the time change.
      # http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html
      # transaction(requires_new: true) do ... end

      # There are probably better ways but I learnt how the Post, Topic, etc. objects fit together by
      # looking at the database tables, then finding out there are Ruby on Rails objects which map
      # directly to them. If you open the Rails Console ("rails c" in Linux's Vagrant or Discourse dir)
      # you can type e.g. Post to get into about the Post object, and Post.find(1) to output the post
      # with ID=1, Post.find(1).topic_id to get the topid ID, etc. Makes things easy to find and play
      # with. Finding the source for each file can also help
      # e.g. https://github.com/discourse/discourse/blob/master/app/models/topic.rb

      post_for_bump = Post.find(post_id)
      
      if post_for_bump.blank?
        return render_json_error("post_id #{post_id} not found")
      end
      
      topic_for_bump = Topic.find(post_for_bump.topic_id)

      if topic_for_bump.blank?
        return render_json_error("post_id #{post_id} -> topic_id #{post_for_bump.topic_id} not found")
      end

      old_bumped_at = topic_for_bump.bumped_at;
      new_bumped_at = post_for_bump.created_at;

      # We use "update!" (throws exceptions on errors) instead of "update" (returns boolean success).
      # All the Discourse code I've looked at calls "update" and doesn't check the result, so I don't
      # know if I'm doing something extra here that isn't needed or not. Failure would be unusual anyway.
      topic_for_bump.update!(bumped_at:         new_bumped_at,
                             last_post_user_id: post_for_bump.user_id)

      # There is also last_posted_at but I think it makes sense to leave that alone.
      # Arguably, we could take the last non-deleted post and use that for the last_post_user_id and last_posted_at
      # while only taking the selected post's bump time, but it depends exactly what the admin's intent is. My
      # personal needs are to reset the thread to the last (possibly only) post after edits to correct formatting,
      # or I'll want to stop someone's gratuitous bump from pushing a thread to the front page. So bumped_at makes
      # sense in both cases. I'd also like to be able to fix the problem where delete, then undelete, of the last
      # post doesn't fix the last_post_user_id and avatar shown in the Lastest page back to the undeleted post's
      # author. So I want to update last_post_user_id but I don't really care if it's to the selected post or the
      # last post as they'll usually be the same for me, unless I'm trying to bury someone's post in which case
      # I don't really care if their face is hidden from lower down the Latest list or not; for now, it will be.

      # Log the action, since it can be used by a nefarious staff member to hide edits that shouldn't be hidden.
      # https://github.com/discourse/discourse/blob/master/app/services/staff_action_logger.rb
      # Search the source for log_custom for examples.
      # Go to http://localhost:4000/admin/logs/staff_action_logs to see the log.

      thread_url_path = "/t/#{topic_for_bump.slug}/#{topic_for_bump.id}/#{post_for_bump.post_number}"

      StaffActionLogger.new(current_user).log_custom('reset_post_bump',
             post_id: post_id,
             previous_value: old_bumped_at,
             new_value: new_bumped_at,
             context: thread_url_path )

      # Return a success flag back to the caller.
      # If we don't do this, their "catch(popupAjaxError)" stuff will be triggered.
      return render json: success_json

    end
  end

  # Map calls below our URL to methods in our module.
  # So far, we just map a "post" (as opposed to "get" etc.) on our root "/" to the "bump" method.
  # An AJAX post to http://localhost:4000/reset_bump/" triggers DiscourseResetBump::bump, above.
  # StaffConstraint is an extra check to ensure only staff can use our URLs.
  # As we have before_action callbacks for the whole plugin, StaffConstraint is probably redundant.
  # StaffConstraint also causes a harsher 404 error if trying to access the blocked URL while
  # the before_action :ensure_logged_in gives a "you must be logged in" type of message and
  # the before_action :ensure_staff gives a "you don't have permission" type of message.
  # The more descriptive errors may be better or worse depending on how visible you want the API to be.
  # https://github.com/discourse/discourse/blob/master/lib/staff_constraint.rb
  require_dependency "staff_constraint"
  DiscourseResetBump::Engine.routes.draw do
    post '/' => 'reset_bump#bump', constraints: StaffConstraint.new
  end

  # This makes it so "http://www.site.com/reset_bump" (and deeper paths) comes to our engine.
  # If you go to http://localhost:4000/randomstring on a dev server (and assuming nothing is
  # actually hooked up to "randomstring") it will show an error page with a huge table of all
  # the routes, which helps understand this and the above Engine.routes.draw part.
  # This only sets up the server side of the route.
  # The user cannot navigate to this URL and see anything in a browser unless the client side
  # also has a route set up (an "Ember Route"), but we don't actually need that for this plugin.
  # Our URL is only going to be called via AJAX, not via navigating to it directly.
  Discourse::Application.routes.append do
    mount ::DiscourseResetBump::Engine, at: "/reset_bump"
  end

end
