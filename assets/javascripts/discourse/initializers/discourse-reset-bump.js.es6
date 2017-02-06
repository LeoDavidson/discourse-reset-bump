import { withPluginApi } from 'discourse/lib/plugin-api';

// resetBumpClicked is run when the "Reset Bump To Here" button is clicked.
function resetBumpClicked()
{
	alert('The button was clicked!');
}

// resetBumpButtonDecorateCallback sets the "Reset Bump To Here" buttons icon and label, and gives it an internal name.
// Note that this callback is not called until the menu is shown, and is called each time it is shown. The callback is
// stored but not called during initialization.
function resetBumpButtonDecorateCallback(dec)
{
	// buttonAttr seems to need to be a "var" local variable, or an inline argument
	// to the function (most plugin code uses the latter, but I'm splitting it out
	// to make things more simple and explicit). If it's a non-var global variable
	// then the menu breaks or has nothing added to it. I am not sure why. I guess
	// the map that is passed in has something destructive done to it so it only
	// works the first time it is used, or something.
	var buttonAttr =
	{
		icon: 'calendar-times-o',			// Find icon names here: http://fontawesome.io/icons/ Remove an "fa" prefix.
		label: 'reset_bump.button_label',	// Name of translated string from (if English): config/locales/client.en.yml
		action: 'actionResetBump'			// Internal name, used to refer to the button in subsequent code.
	}

	// dec is a DecoratorHelper object passed in from Discourse when it calls us.
	// dec.attach adds a new button, in this case with type 'post-admin-menu-button' and the attributes above.
	return dec.attach('post-admin-menu-button', buttonAttr);
}

function apiInitCallback(api)
{
	// Add a new button to the bottom of the Post Admin Menu. resetBumpButtonDecorateCallback (above) is called to do this.
	// resetBumpButtonDecorateCallback gives the new button the internal name "actionResetBump".
	api.decorateWidget('post-admin-menu:after', resetBumpButtonDecorateCallback);
	// Using the internal name "actionResetBump" to find the new button again, make it so clicking the button calls resetBumpClicked.
	api.attachWidgetAction('post-admin-menu', 'actionResetBump', resetBumpClicked);
}

// Discourse will call our initializer by importing our defualt object and calling the initialize function inside it.
// It does this for all .js.es6 files in the initializers folder this one is in.
export default
{
	// The name attribute has to be unique. Beyond that I don't know what it is used for.
	name: 'init-reset-bump',

	// Discourse will call this when the client side starts.
	initialize(container)
	{
		// If the plugin is disabled or the user isn't 'staff', do nothing.
		// This only hides the button from people who aren't allowed to used it.
		// We need to enforce the staff check on the server side as well, since nothing
		// stops a client faking the ajax requests even if the button is hidden.
		// Since we check this at initialization, if the plugin is enabled or disabled
		// it won't take effect in someone's existing session until they reload js app/page.
		// That's normal and fine; the ability to disable plugins is really just there in case
		// they start causing problems and need to be quickly turned off without a server restart.
		const siteSettings = container.lookup('site-settings:main');
		const currentUser = container.lookup('current-user:main');
		if (!siteSettings.reset_bump_enabled || !currentUser || !currentUser.staff)
		{
			return;
		}

		// withPluginApi is imported from Discourse itself, and provides a versioned plugin API
		// which should help future-proof plugins against API changes, or at least make them harmless
		// if the API has to be broken. 0.7 is the current API level as of 5/Feb/2017.
		// We pass withPluginApi our callback function, which is given the api object to set things up.
		// Our callback may not be called at all if the version we are requesting is no longer supported one day.
		// See: https://meta.discourse.org/t/a-new-versioned-api-for-client-side-plugins/40051
		// See: https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/plugin-api.js.es6
		withPluginApi('0.7', apiInitCallback);
	}
};
