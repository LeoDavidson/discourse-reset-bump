// https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/plugin-api.js.es6
import { withPluginApi } from 'discourse/lib/plugin-api';

// https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/ajax.js.es6
import { ajax } from 'discourse/lib/ajax';

// https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/ajax-error.js.es6
import { popupAjaxError } from 'discourse/lib/ajax-error';

// resetBumpClicked is run when the "Reset Bump To Here" button is clicked.
function resetBumpClicked() {
	// this.attrs is set up by the framework when it calls us.
	// It will be different for buttons added to different places. To list what's inside it:
	// Object.keys(this.attrs).forEach(function(key,index) { alert('Key = ' + key); });

	// Get the unique ID of the post that we've been invoked on. The server can find everything
	// else it needs from just this, as the posts database table links the post to its thread, the
	// post's author, and the post's time. We could send these through (they're in this.attrs as
	// well) but it's more robust to have the server decide than have it rely on the client.
	// Client-side ajax calls can be faked, although in this case you'd still need to be "staff".
	// It also means we don't have any client/server date/time/timezone/format issues to worry about
	// and we send less data over the wire.
	const post_id = this.attrs.id;

	const ajaxParams = {
		type: 'POST',
		data: { post_id: post_id }
	};

	// ".catch(popupAjaxError)" below means that if the "ajax" call fails, we'll display a nice
	// modal error message box with an OK button. The popupAjaxError helper takes care of it for us.

	ajax("/reset_bump", ajaxParams).catch(popupAjaxError);
}

// resetBumpButtonDecorateCallback sets the "Reset Bump To Here" button's icon, label, and internal name.
// This callback is not called until the menu is shown, and is called each time it is shown.
// The callback is stored but not called during initialization.
function resetBumpButtonDecorateCallback(dec) {
	// buttonAttr seems to need to be a var or const local variable, or an inline argument
	// to the function. (Most plugin code uses an inline argument, but I'm splitting things
	// out to make everything more simple and explicit). If buttonAttr is declared without
	// "var" or "const" (or maybe "let") then the menu breaks or has nothing added to it.
	// Maybe related to this: http://stackoverflow.com/questions/41792503/node-js-callback-not-defined-when-trying-to-to-a-http-request
	const buttonAttr = {
		icon: 'calendar-times-o',			// Find icon names here: http://fontawesome.io/icons/
		label: 'reset_bump.button_label',	// Name of string in e.g. config/locales/client.en.yml
		action: 'actionResetBump'			// Internal name, used to refer to the button below.
	};

	// dec is a DecoratorHelper object passed in from Discourse when it calls us.
	// We use dec.attach to add a new button of type 'post-admin-menu-button' and the attributes above.
	return dec.attach('post-admin-menu-button', buttonAttr);
}

function apiInitCallback(api)
{
	// If the plugin is disabled, do nothing.
	// Since we check this at initialization, if the plugin is enabled or disabled
	// it won't take effect in someone's existing session until they reload js app/page.
	// That's normal and fine; the ability to disable plugins is really just there in case
	// they start causing problems and need to be quickly turned off without a server restart.
	const siteSettings = api.container.lookup('site-settings:main');
	
	if (!siteSettings.reset_bump_enabled) {
		return;
	}

	// If there is no user, or they are not "staff", do nothing.
	// This only hides the button from people who aren't allowed to used it.
	// We need to enforce the staff check on the server side as well, since nothing
	// stops a client faking the ajax requests even if the button is hidden.
	const currentUser = api.getCurrentUser();

	if (!currentUser || !currentUser.staff) {
		return;
	}

	// Add a new button to the bottom of the Post Admin Menu. resetBumpButtonDecorateCallback (above) is
	// called to do this, and will give the new button the internal name "actionResetBump".
	api.decorateWidget('post-admin-menu:after', resetBumpButtonDecorateCallback);

	// Find the button again, using the name we gave it, and make it run resetBumpClicked when clicked.
	api.attachWidgetAction('post-admin-menu', 'actionResetBump', resetBumpClicked);

	// This is how you would add a button to the main set of icons directly under each post.
	// Useful for testing server-side permission checks, since there's no way to even see the
	// post-admin-menu if not logged in as staff, but not where I want the button in the finished plugin.
	// Unlike other code, I've used an inline function here so I only need to comemnt-out one block.
	// You can use inline functions (and inline functions within inline functions) for most of this whole
	// file if you wish, and most example plugins do, but I found it made them harder to follow as a beginner.
	/*
	api.addPostMenuButton('actionResetBump2', attrs => {
			return {
				action: 'actionResetBump2',       // As in resetBumpButtonDecorateCallback.
				icon: 'calendar-times-o',         // As in resetBumpButtonDecorateCallback.
				className: 'actionResetBump2',    // Becomes part of button's css class. Useful for css mods.
				title: 'reset_bump.button_label', // Like "label" in resetBumpButtonDecorateCallback.
				position: 'first'                 // Make it the first icon in the row.
			};
		}
	);
	api.attachWidgetAction('post', 'actionResetBump2', resetBumpClicked);
	*/
}

// Discourse will call our initializer by importing our defualt object and calling our initialize function.
// It does this for all .js.es6 files in the initializers folder.
export default {
	// The name here has to be unique. Not sure what it's used for exactly.
	name: 'init-reset-bump',

	// Discourse will call initialize when the client side starts.
	// Plugins for older versions also take a "container" argument but it's also given to us
	// via the "api" object passed to our apiInitCallback callback, so we ignore it here.
	initialize() {
		// withPluginApi is imported from Discourse itself, and provides a versioned plugin API
		// which should help future-proof plugins against API changes, or at least make them harmless
		// if the API has to be broken. 0.7 is the current API level as of 5/Feb/2017.
		// We pass withPluginApi our callback function, which is given the api object to set things up.
		// Our callback may not be called at all if the version we are requesting becomes unsupported.
		// See: https://meta.discourse.org/t/a-new-versioned-api-for-client-side-plugins/40051
		// See: https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/plugin-api.js.es6
		withPluginApi('0.7', apiInitCallback);
	}
};
