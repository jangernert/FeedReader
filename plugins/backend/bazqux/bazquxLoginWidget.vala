//--------------------------------------------------------------------------------------
// This is the plugin that extends user-interface of FeedReader
// It adds all the necessary widgets to the interface to log into the service.
// User- and password-entries, or redirect to a website to log in.
//--------------------------------------------------------------------------------------
FeedReader.Logger logger;

public class FeedReader.bazquxLoginWidget : Peas.ExtensionBase, LoginInterface {


	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private bazquxUtils m_utils;
	//--------------------------------------------------------------------------------------
	// The stack with all the login-widgets for the different services.
	// Add widget and name it just like the plugin itself.
	//--------------------------------------------------------------------------------------
	public Gtk.Stack m_stack { get; construct set; }


	//--------------------------------------------------------------------------------------
	// Model for the dropdown-menu to choose the service.
	// Add new Gtk.TreeIter with first column as name
	// and second column as id plugin-name + "UI".
	//--------------------------------------------------------------------------------------
	public Gtk.ListStore m_listStore { get; construct set; }


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
		m_utils = new bazquxUtils();

		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_userEntry.activate.connect(() => { login(); });
		m_passwordEntry.activate.connect(() => { login(); });

		m_passwordEntry.set_invisible_char('*');
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		grid.attach(user_label, 0, 0, 1, 1);
		grid.attach(m_userEntry, 1, 0, 1, 1);
		grid.attach(password_label, 0, 1, 1, 1);
		grid.attach(m_passwordEntry, 1, 1, 1, 1);

		var logo = new Gtk.Image.from_file(m_installPrefix + "/share/icons/hicolor/64x64/places/feed-service-bazqux.svg");

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(grid, true, true, 10);
		box.show_all();

		m_stack.add_named(box, "bazquxUI");

		Gtk.TreeIter iter;
		m_listStore.append(out iter);
		m_listStore.set(iter, 0, _("BazQux"), 1, "bazquxUI");

		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());
	}


	//--------------------------------------------------------------------------------------
	// Return wheather the plugin needs a webview to log in via oauth.
	//--------------------------------------------------------------------------------------
	public bool needWebLogin()
	{
		return false;
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
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
	}


	//--------------------------------------------------------------------------------------
	// Only needed if "needWebLogin()" retruned true. Return URL that should be
	// loaded to log in via website.
	//--------------------------------------------------------------------------------------
	public string buildLoginURL()
	{
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Extract access-key from redirect-URL from webview after loggin in with
	// the webview.
	// Return "true" if extracted sucessfuly, "false" otherwise.
	//--------------------------------------------------------------------------------------
	public bool extractCode(string redirectURL)
	{
		return false;
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
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.bazquxLoginWidget));
}
