# name: discourse-reset-bump
# about: Gives staff a quick button for resetting a topic's bump time to that of a particular post.
# version: 0.1
# authors: Leo Davidson
# url: https://github.com/leodavidson/discourse-reset-bump

# The comments above are not just comments. Discourse will parse them for the plugin name etc.

# Declare that one of the things in config/settings.yml turns the whole plugin on and off.
# Discourse uses this for the Enabled Y/N field. It's up to us to check it in our code as well.
enabled_site_setting :reset_bump_enabled
