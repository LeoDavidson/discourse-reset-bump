# UNFINISHED WORK IN PROGRESS
# DO NOT USE THIS YET

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

## Installation

Follow the [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) howto, using
`git clone https://github.com/leodavidson/discourse-reset-bump.git` as the plugin command.

Once you've installed it, it will be enabled by default and can be disbaled under the
site's admin / plugin settings area, via the `reset_bump_enabled` checkbox.

## Issues

If you have issues or suggestions for the plugin, please contact leo@pretentiousname.com

## License

MIT
