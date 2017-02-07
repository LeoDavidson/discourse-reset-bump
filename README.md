### discourse-reset-bump

This plugin gives staff members a button to quickly reset a thread's bump time to the
original time of any post within the thread. The button is added to the admin menu
(spanner icon) for each post.

This is useful if you make minor edits to the last post and don't want the thread bumped
or if the wrong person/post are currently marked as the latest in the thread due to
a delete or un-delete of a later post.

The ability to change the timestamp of a thread is built in to Discourse, but the UI for
doing so is modal and requires you to separately select the date and time. You can only
see the detailed date and time of a post in another modal UI, and cannot copy and paste
between the two UIs as they use different formats. So the plugin does not let you do
anything you could not do already (other than repairing the last post/poster if they go
wrong), it just lets you do things more conveniently.

Each use of the *Reset Bump To Here* button will be logged in the Discourse staff actions
log, including the topic and post IDs and URL, and old and new timestamps. This can help
detect abuse of the functionality (e.g. to hide new posts from other admins, rather than
the intended use of avoiding bumps when making formatting-only fixes to old threads, or
undoing a user's gratuitous bump without deleting their message entirely.)

**For developers:** The source code is extensively commented and I've aimed to do things
in the most simple way possible (expanding most inline functions into top-level ones so
you can more easily see the structure of things). This is the first Discourse plugin I've
written, the first Ruby (let alone Ruby on Rails), and the first time I've used Javascript
as much more than a stand-in for VBScript. I've got years of C++ and C# experience but
found it hard to work out all of this, so I felt I could help others by putting detailed
comments in the code that explain what is being done and why. In terms of what the plugin
does, it adds buttons below the post on the client side, checks for "staff" access on
both the server and client sides, and when the button is clicked it causes the server side
to finds a topics and post by ID and then modifies some of their database fields. All easy
once you know how, but days of unravelling source code, (outdated) forum threads, multiple
languages and frameworks if you are new to it. I also recommend looking at other plugins
to see how you can write things in a "nicer" (or at least more compact!) way once you
understand what's going on in this one. This one's code is meant to be easy to understand
and not necessarily the "best" way to do things. I hope it helps you!

## Installation

Follow the [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) howto, using
`git clone https://github.com/leodavidson/discourse-reset-bump.git` as the plugin command.

Once you've installed it, it will be enabled by default and can be disabled under the
site's admin / plugin settings area, via the `reset_bump_enabled` checkbox.

## Issues

If you have issues or suggestions for the plugin, please contact leo@pretentiousname.com

## License

MIT
