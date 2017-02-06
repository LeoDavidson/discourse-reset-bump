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
    # The Admin::AdminController mentioned in "Creating Routes in Discourse and Showing Data"
    # is (at the time of writing) identical to ::ApplicationController that we inherit from
    # except that it has these two checks built in. I'm not sure if we can or should use 
    # Admin::AdminController from a plugin (other plugins I looked at don't, and I can't
    # work out what to change the "require_dependency" line above to for the Admin version)
    # so we inherit from the basic one and do the two tests ourselves.
    # You'll find other plugins and Discourse code using before_filter instead of
    # before_action. Both do the same thing in Rails 4.2, so we can use either. Rails 5.0
    # makes 'before_filter' deprecated and start causing warnings, and Rails 5.1 will remove
    # it entirely, so let's use the newer name from the start. We're on Rails 4.2 as of writing.
    # See: http://stackoverflow.com/questions/16519828/rails-4-before-filter-vs-before-action
    before_action :ensure_logged_in
    before_action :ensure_staff
    
    # Each method name corresponds to one of the Engine.routes.draw things below.
    def bump
      # As we call to_i, post_id will be 0 if it isn't there at all.
      # There is never a post with id 0 so we'll fail rather than change the wrong thing.
      post_id = params[:postId].to_i
      puts("Bump post_id: #{post_id}")

      post_for_bump = Post.find(post_id)
      topic_for_bump = Topic.find(post_for_bump.topic_id)
      user_for_bump = post_for_bump.user_id
      time_for_bump = post_for_bump.created_at

      puts("-----------------------------------------------------------------------------------------------")
      puts("--- BUMPING --- #{topic_for_bump.title} for user id #{user_for_bump} to time #{time_for_bump}")
      puts("-----------------------------------------------------------------------------------------------")

      # Return a success flag back to the caller.
      # If we don't do this, their "catch(popupAjaxError)" stuff will be triggered.
      render json: success_json
    end
  end

  # Map calls below our URL to methods in our module.
  # So far, we just map a "post" (as opposed to "get" etc.) on our root "/" to the "bump" method.
  # An AJAX post to http://localhost:4000/reset_bump/" triggers DiscourseResetBump::bump, above.
  # StaffConstraint is an extra check to ensure only staff can use our URLs.
  # As we have before_action callbacks for the whole plugin, StaffConstraint is probably redundant.
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
