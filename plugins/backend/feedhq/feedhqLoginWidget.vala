//--------------------------------------------------------------------------------------
// This is the plugin that extends user-interface of FeedReader
// It adds all the necessary widgets to the interface to log into the service.
// User- and password-entries, or redirect to a website to log in.
//--------------------------------------------------------------------------------------

public class FeedReader.FeedHQLoginWidget : Peas.ExtensionBase, LoginInterface {


	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private FeedHQUtils m_utils;

	public void init()
	{
		m_utils = new FeedHQUtils();
	}

	public string getWebsite()
	{
		return "https://feedhq.org/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.HOSTED | BackendFlags.PROPRIETARY | BackendFlags.PAID);
	}

	public string getID()
	{
		return "feedhq";
	}

	public string iconName()
	{
		return "feed-service-feedhq";
	}

	public string serviceName()
	{
		return "FeedHQ";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
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

		var logo = new Gtk.Image.from_icon_name("feed-service-feedhq", Gtk.IconSize.MENU);

		var loginLabel = new Gtk.Label(_("Please log in to FeedHQ and enjoy using FeedReader"));
		loginLabel.get_style_context().add_class("h2");
		loginLabel.set_justify(Gtk.Justification.CENTER);
		loginLabel.set_lines(3);

		var loginButton = new Gtk.Button.with_label(_("Login"));
		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => { login(); });

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.valign = Gtk.Align.CENTER;
		box.halign = Gtk.Align.CENTER;
		box.pack_start(loginLabel, false, false, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(grid, true, true, 10);
		box.pack_end(loginButton, false, false, 20);

		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());

		return box;
	}

	public void showHtAccess()
	{

	}

	public void writeData()
	{
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
	}


	public async void postLoginAction()
	{
		return;
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}

	public string buildLoginURL()
	{
		return "";
	}
}


[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.FeedHQLoginWidget));
}
