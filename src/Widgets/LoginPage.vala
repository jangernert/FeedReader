public class FeedReader.LoginPage : Gtk.Bin {

	private Gtk.Entry m_ttrss_url_entry;
	private Gtk.Entry m_ttrss_user_entry;
	private Gtk.Entry m_ttrss_password_entry;
	private Gtk.Entry m_owncloud_url_entry;
	private Gtk.Entry m_owncloud_user_entry;
	private Gtk.Entry m_owncloud_password_entry;
	private Gtk.ComboBox m_comboBox;
	private Gtk.Stack m_login_details;
	private Gtk.Box m_layout;
	private string[] m_account_types;
	public signal void submit_data();
	public signal void loginError(int errorCode);
	public signal void loadLoginPage(OAuth type);


	public LoginPage()
	{

		m_account_types = {_("Tiny Tiny RSS"), _("Feedly"), _("OwnCloud")};
		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_layout.set_size_request(700, 410);

		var welcomeText = new Gtk.Label(_("Where are your feeds?"));
		welcomeText.get_style_context().add_class("h1");
		welcomeText.set_justify(Gtk.Justification.CENTER);

		var welcomeText2 = new Gtk.Label(_("Please select the RSS service you are using and log in to get going."));
		welcomeText2.get_style_context().add_class("h2");
		welcomeText2.set_justify(Gtk.Justification.CENTER);
		welcomeText2.set_lines(3);


		m_layout.pack_start(welcomeText, false, true, 0);
		m_layout.pack_start(welcomeText2, false, true, 2);


		var liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter ttrss;
		liststore.append(out ttrss);
		liststore.set(ttrss, 0, m_account_types[Backend.TTRSS]);
		Gtk.TreeIter feedly;
		liststore.append(out feedly);
		liststore.set(feedly, 0, m_account_types[Backend.FEEDLY]);
		Gtk.TreeIter ownCloud;
		//liststore.append(out ownCloud);
		//liststore.set(ownCloud, 0, m_account_types[Backend.OWNCLOUD]);
		m_comboBox = new Gtk.ComboBox.with_model(liststore);

		Gtk.CellRendererText renderer = new Gtk.CellRendererText();
		m_comboBox.pack_start (renderer, false);
		m_comboBox.add_attribute(renderer, "text", 0);
		m_comboBox.set_size_request(300, 0);
		m_comboBox.set_valign(Gtk.Align.CENTER);
		m_comboBox.set_halign(Gtk.Align.CENTER);

		m_login_details = new Gtk.Stack();
		m_login_details.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_login_details.set_transition_duration(100);

		var buttonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var loginButton = new Gtk.Button.with_label(_("Login"));
		loginButton.clicked.connect(write_login_data);
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		buttonBox.pack_end(loginButton, false, false, 0);

		m_layout.pack_start(m_comboBox, false, false, 20);
		m_layout.pack_start(m_login_details, false, true, 10);
		m_layout.pack_start(buttonBox, false, true, 0);


		m_comboBox.changed.connect(() => {
			if(m_comboBox.get_active() != -1) {
				switch(m_comboBox.get_active())
				{
					case Backend.NONE:
						m_login_details.set_visible_child_name("none");
						break;
					case Backend.TTRSS:
						m_login_details.set_visible_child_name("ttrss");
						break;
					case Backend.FEEDLY:
						m_login_details.set_visible_child_name("feedly");
						break;
					case Backend.OWNCLOUD:
						m_login_details.set_visible_child_name("owncloud");
						break;
				}
			}
		});

		var nothing_selected = new Gtk.Label(_("No service selected."));
		nothing_selected.get_style_context().add_class("h3");
		m_login_details.add_named(nothing_selected, "none");
		setup_ttrss_login();
		setup_feedly_login();
		setup_owncloud_login();

		this.set_halign(Gtk.Align.CENTER);
		this.set_valign(Gtk.Align.CENTER);
		this.margin = 20;
		this.add(m_layout);
		this.show_all();
	}


	private void setup_ttrss_login()
	{
		var ttrss_url_label = new Gtk.Label(_("TinyTinyRSS URL:"));
		var ttrss_user_label = new Gtk.Label(_("Username:"));
		var ttrss_password_label = new Gtk.Label(_("Password:"));

		ttrss_url_label.set_alignment(1.0f, 0.5f);
		ttrss_user_label.set_alignment(1.0f, 0.5f);
		ttrss_password_label.set_alignment(1.0f, 0.5f);

		ttrss_url_label.set_hexpand(true);
		ttrss_user_label.set_hexpand(true);
		ttrss_password_label.set_hexpand(true);

		m_ttrss_url_entry = new Gtk.Entry();
		m_ttrss_user_entry = new Gtk.Entry();
		m_ttrss_password_entry = new Gtk.Entry();

		m_ttrss_url_entry.activate.connect(write_login_data);
		m_ttrss_user_entry.activate.connect(write_login_data);
		m_ttrss_password_entry.activate.connect(write_login_data);

		m_ttrss_password_entry.set_invisible_char('*');
		m_ttrss_password_entry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		Gdk.Pixbuf tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/ttrss.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var ttrss_logo = new Gtk.Image.from_pixbuf(tmp_logo);

		grid.attach(ttrss_url_label, 0, 0, 1, 1);
		grid.attach(m_ttrss_url_entry, 1, 0, 1, 1);
		grid.attach(ttrss_user_label, 0, 1, 1, 1);
		grid.attach(m_ttrss_user_entry, 1, 1, 1, 1);
		grid.attach(ttrss_password_label, 0, 2, 1, 1);
		grid.attach(m_ttrss_password_entry, 1, 2, 1, 1);

		var ttrss_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		ttrss_box.pack_start(ttrss_logo, false, false, 10);
		ttrss_box.pack_start(grid, true, true, 10);

		m_login_details.add_named(ttrss_box, "ttrss");
	}


	private void setup_feedly_login()
	{
		var tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/feedly.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var feedly_logo = new Gtk.Image.from_pixbuf(tmp_logo);

		var text = new Gtk.Label(_("You will be redirected to the feedly website where you can use your Facebook-, Google-, Twitter-, Microsoft- or Evernote-Account to log in."));
		text.get_style_context().add_class("h3");
		text.set_justify(Gtk.Justification.CENTER);
		text.set_line_wrap_mode(Pango.WrapMode.WORD);
		text.set_line_wrap(true);
		text.set_lines(3);
		text.expand = false;
		text.set_width_chars(60);
		text.set_max_width_chars(60);

		var feedly_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		feedly_box.pack_start(feedly_logo, false, false, 20);
		feedly_box.pack_start(text, false, false, 10);
		m_login_details.add_named(feedly_box, "feedly");
	}


	private void setup_owncloud_login()
	{
		var owncloud_url_label = new Gtk.Label(_("OwnCloud URL:"));
		var owncloud_user_label = new Gtk.Label(_("Username:"));
		var owncloud_password_label = new Gtk.Label(_("Password:"));

		owncloud_url_label.set_alignment(1.0f, 0.5f);
		owncloud_user_label.set_alignment(1.0f, 0.5f);
		owncloud_password_label.set_alignment(1.0f, 0.5f);

		owncloud_url_label.set_hexpand(true);
		owncloud_user_label.set_hexpand(true);
		owncloud_password_label.set_hexpand(true);

		m_owncloud_url_entry = new Gtk.Entry();
		m_owncloud_user_entry = new Gtk.Entry();
		m_owncloud_password_entry = new Gtk.Entry();

		m_owncloud_url_entry.activate.connect(write_login_data);
		m_owncloud_user_entry.activate.connect(write_login_data);
		m_owncloud_password_entry.activate.connect(write_login_data);

		m_owncloud_password_entry.set_invisible_char('*');
		m_owncloud_password_entry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		var tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/owncloud.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var owncloud_logo = new Gtk.Image.from_pixbuf(tmp_logo);

		grid.attach(owncloud_url_label, 0, 0, 1, 1);
		grid.attach(m_owncloud_url_entry, 1, 0, 1, 1);
		grid.attach(owncloud_user_label, 0, 1, 1, 1);
		grid.attach(m_owncloud_user_entry, 1, 1, 1, 1);
		grid.attach(owncloud_password_label, 0, 2, 1, 1);
		grid.attach(m_owncloud_password_entry, 1, 2, 1, 1);

		var owncloud_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		owncloud_box.pack_start(owncloud_logo, false, false, 10);
		owncloud_box.pack_start(grid, true, true, 10);

		m_login_details.add_named(owncloud_box, "owncloud");
	}

	public void loadData()
	{
		switch(settings_general.get_enum("account-type"))
		{
			case Backend.NONE:
				m_comboBox.set_active(Backend.NONE);
				m_login_details.set_visible_child_name("none");
				break;
			case Backend.TTRSS:
				m_comboBox.set_active(Backend.TTRSS);
				m_login_details.set_visible_child_name("ttrss");
				break;
			case Backend.FEEDLY:
				m_comboBox.set_active(Backend.FEEDLY);
				m_login_details.set_visible_child_name("feedly");
				break;
			case Backend.OWNCLOUD:
				m_comboBox.set_active(Backend.OWNCLOUD);
				m_login_details.set_visible_child_name("owncloud");
				break;
		}

		if(settings_general.get_enum("account-type") == Backend.OWNCLOUD)
		{
			string url = ""; //FIXME feedreader_settings.get_string("url");
			string username = ""; //FIXME feedreader_settings.get_string("username");
			m_owncloud_url_entry.set_text(url);
			m_owncloud_user_entry.set_text(username);

			var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
				                              "URL", Secret.SchemaAttributeType.STRING,
				                              "Username", Secret.SchemaAttributeType.STRING);

			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = url;
			attributes["Username"] = username;

			string passwd = "";
			try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}
			m_owncloud_password_entry.set_text(passwd);
		}

		if(settings_general.get_enum("account-type") == Backend.TTRSS)
		{
			string url = settings_ttrss.get_string("url");
			string username = settings_ttrss.get_string("username");
			m_ttrss_url_entry.set_text(url);
			m_ttrss_user_entry.set_text(username);

			var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
											"URL", Secret.SchemaAttributeType.STRING,
											"Username", Secret.SchemaAttributeType.STRING);

			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = url;
			attributes["Username"] = username;

			string passwd = "";
			try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}
			m_ttrss_password_entry.set_text(passwd);
		}
	}


	private void write_login_data()
	{
		logger.print(LogMessage.DEBUG, "write login data");
		switch(m_comboBox.get_active())
		{
			case Backend.TTRSS:
				settings_general.set_enum("account-type", Backend.TTRSS);
				string url = m_ttrss_url_entry.get_text();
				settings_ttrss.set_string("url", url);
				settings_ttrss.set_string("username", m_ttrss_user_entry.get_text());
				var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "URL", Secret.SchemaAttributeType.STRING,
							                      "Username", Secret.SchemaAttributeType.STRING);
				var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
				attributes["URL"] = url;
				attributes["Username"] = m_ttrss_user_entry.get_text();
				try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_ttrss_password_entry.get_text(), null);}
				catch(GLib.Error e){}
				break;

			case Backend.FEEDLY:
				logger.print(LogMessage.DEBUG, "write type feedly");
				settings_general.set_enum("account-type", Backend.FEEDLY);
				loadLoginPage(OAuth.FEEDLY);
				return;

			case Backend.OWNCLOUD:
				settings_general.set_enum("account-type", Backend.OWNCLOUD);
				break;

			case Backend.NONE:
				settings_general.set_enum("account-type", Backend.NONE);
				break;
		}

		var status = feedDaemon_interface.login(settings_general.get_enum("account-type"));
		logger.print(LogMessage.DEBUG, "LoginPage: status = %i".printf(status));
		if(status == LoginResponse.SUCCESS)
		{
			submit_data();
			return;
		}

		loginError(status);
	}
}
