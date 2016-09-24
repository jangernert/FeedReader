//--------------------------------------------------------------------------------------
// This is the plugin that extends user-interface of FeedReader
// It adds all the necessary widgets to the interface to log into the service.
// User- and password-entries, or redirect to a website to log in.
//--------------------------------------------------------------------------------------

public class FeedReader.demoLoginWidget : Peas.ExtensionBase, LoginInterface {

	//--------------------------------------------------------------------------------------
	// Can be used to print messages to the commandline which are also
	// written to the harddrive.
	//--------------------------------------------------------------------------------------
	public Logger m_logger { get; construct set; }


	//--------------------------------------------------------------------------------------
	// The install prefix the user (or packager) chooses when building FeedReader
	// Useful to load custom icons installed alongside the plugin.
	//--------------------------------------------------------------------------------------
	public string m_installPrefix { get; construct set; }


	//--------------------------------------------------------------------------------------
	// Called when loading plugin. Setup all the widgets here and add them to
	// m_stack and m_listStore.
	// The signal "login()" can be emmited when try to log in.
	// For example after pressing "enter" in the password-entry.
	//--------------------------------------------------------------------------------------
	public void init()
	{
		//--------------------------------------------------------------------------------------
		// m_stack.add_named(demoWidget, "demoUI");
		// Gtk.TreeIter iter;
		// m_listStore.append(out iter);
		// m_listStore.set(iter, 0, _("Demo Service 123"), 1, "demoUI");
		//--------------------------------------------------------------------------------------
	}


	//--------------------------------------------------------------------------------------
	// Return the name of the service-icon (non-symbolic).
	//--------------------------------------------------------------------------------------
	public string iconName()
	{

	}


	//--------------------------------------------------------------------------------------
	// Return the name of the service as displayed to the user
	//--------------------------------------------------------------------------------------
	public string serviceName()
	{

	}


	//--------------------------------------------------------------------------------------
	// Return wheather the plugin needs a webview to log in via oauth.
	//--------------------------------------------------------------------------------------
	public bool needWebLogin()
	{

	}


	//--------------------------------------------------------------------------------------
	// Only important for self-hosted services.
	// If the server is secured by htaccess and a second username and password
	// is required, show the UI to enter those in this methode.
	// If htaccess won't be needed do nothing here.
	//--------------------------------------------------------------------------------------
	public void showHtAccess()
	{

	}

	//--------------------------------------------------------------------------------------
	// Methode gets executed before logging in. Write all the data gathered
	// into gsettings (password, username, access-key).
	//--------------------------------------------------------------------------------------
	public void writeData()
	{

	}


	//--------------------------------------------------------------------------------------
	// Only needed if "needWebLogin()" retruned true. Return URL that should be
	// loaded to log in via website.
	//--------------------------------------------------------------------------------------
	public string buildLoginURL()
	{

	}


	//--------------------------------------------------------------------------------------
	// Extract access-key from redirect-URL from webview after loggin in with
	// the webview.
	// Return "true" if extracted sucessfuly, "false" otherwise.
	//--------------------------------------------------------------------------------------
	public bool extractCode(string redirectURL)
	{

	}
}


//--------------------------------------------------------------------------------------
// Boilerplate code for the plugin. Replace "demoLoginWidget" with the name
// of your interface-class.
//--------------------------------------------------------------------------------------
[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.demoLoginWidget));
}
