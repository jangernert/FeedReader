//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.LoginPage : Gtk.Bin {

	private Gtk.Entry m_ttrss_url_entry;
	private Gtk.Entry m_ttrss_user_entry;
	private Gtk.Entry m_ttrss_password_entry;
	private Gtk.Entry m_ttrss_auth_pw_entry;
	private Gtk.Entry m_ttrss_auth_user_entry;
	private Gtk.Revealer m_ttrss_revealer;
	private Gtk.Entry m_owncloud_url_entry;
	private Gtk.Entry m_owncloud_user_entry;
	private Gtk.Entry m_owncloud_password_entry;
	private Gtk.Entry m_owncloud_auth_user_entry;
	private Gtk.Entry m_owncloud_auth_pw_entry;
	private Gtk.Revealer m_owncloud_revealer;
	private Gtk.Entry m_inoreader_user_entry;
	private Gtk.Entry m_inoreader_password_entry;
	private Gtk.Entry m_inoreader_apikey_entry;
	private Gtk.Entry m_inoreader_apisecret_entry;
	private Gtk.ComboBox m_comboBox;
	private Gtk.Stack m_login_details;
	private Gtk.Box m_layout;
	private string[] m_account_types;
	private bool m_need_htaccess = false;
	public signal void submit_data();
	public signal void loginError(LoginResponse errorCode);
	public signal void loadLoginPage(OAuth type);


	public LoginPage()
	{

		m_account_types = {_("Tiny Tiny RSS"), _("Feedly"), _("OwnCloud"),_("InoReader")};
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
		liststore.append(out ownCloud);
		liststore.set(ownCloud, 0, m_account_types[Backend.OWNCLOUD]);

		Gtk.TreeIter inoReader;
		liststore.append(out inoReader);
		liststore.set(inoReader, 0, m_account_types[Backend.INOREADER]);

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
					case Backend.INOREADER:
						m_login_details.set_visible_child_name("inoreader");
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
		setup_inoreader_login();

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

		grid.attach(ttrss_url_label, 0, 0, 1, 1);
		grid.attach(m_ttrss_url_entry, 1, 0, 1, 1);
		grid.attach(ttrss_user_label, 0, 1, 1, 1);
		grid.attach(m_ttrss_user_entry, 1, 1, 1, 1);
		grid.attach(ttrss_password_label, 0, 2, 1, 1);
		grid.attach(m_ttrss_password_entry, 1, 2, 1, 1);


		// http auth stuff ----------------------------------------------------
		var ttrss_auth_user_label = new Gtk.Label(_("Username:"));
		var ttrss_auth_password_label = new Gtk.Label(_("Password:"));

		ttrss_auth_user_label.set_alignment(1.0f, 0.5f);
		ttrss_auth_password_label.set_alignment(1.0f, 0.5f);

		ttrss_auth_user_label.set_hexpand(true);
		ttrss_auth_password_label.set_hexpand(true);

		m_ttrss_auth_user_entry = new Gtk.Entry();
		m_ttrss_auth_pw_entry = new Gtk.Entry();
		m_ttrss_auth_pw_entry.set_invisible_char('*');
		m_ttrss_auth_pw_entry.set_visibility(false);

		m_ttrss_auth_user_entry.activate.connect(write_login_data);
		m_ttrss_auth_pw_entry.activate.connect(write_login_data);

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(ttrss_auth_user_label, 0, 0, 1, 1);
		authGrid.attach(m_ttrss_auth_user_entry, 1, 0, 1, 1);
		authGrid.attach(ttrss_auth_password_label, 0, 1, 1, 1);
		authGrid.attach(m_ttrss_auth_pw_entry, 1, 1, 1, 1);

		var ttrss_frame = new Gtk.Frame(_("HTTP Authorization"));
		ttrss_frame.set_halign(Gtk.Align.CENTER);
		ttrss_frame.add(authGrid);
		m_ttrss_revealer = new Gtk.Revealer();
		m_ttrss_revealer.add(ttrss_frame);
		//---------------------------------------------------------------------

		var ttrss_logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-ttrss.svg");

		var ttrss_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		ttrss_box.pack_start(ttrss_logo, false, false, 10);
		ttrss_box.pack_start(grid, true, true, 10);
		ttrss_box.pack_start(m_ttrss_revealer, true, true, 10);

		m_login_details.add_named(ttrss_box, "ttrss");
	}


	private void setup_feedly_login()
	{
		var feedly_logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-feedly.svg");

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

		var owncloud_logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-owncloud.svg");

		grid.attach(owncloud_url_label, 0, 0, 1, 1);
		grid.attach(m_owncloud_url_entry, 1, 0, 1, 1);
		grid.attach(owncloud_user_label, 0, 1, 1, 1);
		grid.attach(m_owncloud_user_entry, 1, 1, 1, 1);
		grid.attach(owncloud_password_label, 0, 2, 1, 1);
		grid.attach(m_owncloud_password_entry, 1, 2, 1, 1);

		// http auth stuff ----------------------------------------------------
		var owncloud_auth_user_label = new Gtk.Label(_("Username:"));
		var owncloud_auth_password_label = new Gtk.Label(_("Password:"));

		owncloud_auth_user_label.set_alignment(1.0f, 0.5f);
		owncloud_auth_password_label.set_alignment(1.0f, 0.5f);

		owncloud_auth_user_label.set_hexpand(true);
		owncloud_auth_password_label.set_hexpand(true);

		m_owncloud_auth_user_entry = new Gtk.Entry();
		m_owncloud_auth_pw_entry = new Gtk.Entry();
		m_owncloud_auth_pw_entry.set_invisible_char('*');
		m_owncloud_auth_pw_entry.set_visibility(false);

		m_owncloud_auth_user_entry.activate.connect(write_login_data);
		m_owncloud_auth_pw_entry.activate.connect(write_login_data);

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(owncloud_auth_user_label, 0, 0, 1, 1);
		authGrid.attach(m_owncloud_auth_user_entry, 1, 0, 1, 1);
		authGrid.attach(owncloud_auth_password_label, 0, 1, 1, 1);
		authGrid.attach(m_owncloud_auth_pw_entry, 1, 1, 1, 1);

		var owncloud_frame = new Gtk.Frame(_("HTTP Authorization"));
		owncloud_frame.set_halign(Gtk.Align.CENTER);
		owncloud_frame.add(authGrid);
		m_owncloud_revealer = new Gtk.Revealer();
		m_owncloud_revealer.add(owncloud_frame);
		//---------------------------------------------------------------------

		var owncloud_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		owncloud_box.pack_start(owncloud_logo, false, false, 10);
		owncloud_box.pack_start(grid, true, true, 10);
		owncloud_box.pack_start(m_owncloud_revealer, true, true, 10);

		m_login_details.add_named(owncloud_box, "owncloud");
	}

	private void setup_inoreader_login()
	{

		var inoreader_user_label = new Gtk.Label(_("Username:"));
		var inoreader_password_label = new Gtk.Label(_("Password:"));

		m_inoreader_user_entry = new Gtk.Entry();
		m_inoreader_password_entry = new Gtk.Entry();

		m_inoreader_user_entry.activate.connect(write_login_data);
		m_inoreader_password_entry.activate.connect(write_login_data);

		m_inoreader_password_entry.set_invisible_char('*');
		m_inoreader_password_entry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		var ttrss_logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-inoreader.svg");

		grid.attach(inoreader_user_label, 0, 0, 1, 1);
		grid.attach(m_inoreader_user_entry, 1, 0, 1, 1);
		grid.attach(inoreader_password_label, 0, 1, 1, 1);
		grid.attach(m_inoreader_password_entry, 1, 1, 1, 1);

		var inoreader_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		inoreader_box.pack_start(ttrss_logo, false, false, 10);
		inoreader_box.pack_start(grid, true, true, 10);

		m_login_details.add_named(inoreader_box, "inoreader");
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
			case Backend.INOREADER:
				m_comboBox.set_active(Backend.INOREADER);
				m_login_details.set_visible_child_name("inoreader");
				break;
		}


		m_owncloud_url_entry.set_text(OwncloudNews_Utils.getUnmodifiedURL());
		m_owncloud_user_entry.set_text(OwncloudNews_Utils.getUser());
		m_owncloud_password_entry.set_text(OwncloudNews_Utils.getPasswd());

		m_ttrss_url_entry.set_text(ttrss_utils.getUnmodifiedURL());
		m_ttrss_user_entry.set_text(ttrss_utils.getUser());
		m_ttrss_password_entry.set_text(ttrss_utils.getPasswd());

		m_inoreader_user_entry.set_text(inoreader_utils.getUser());
		m_inoreader_password_entry.set_text(inoreader_utils.getPasswd());
	}


	public void showHtAccess()
	{
		switch(m_comboBox.get_active())
		{
			case Backend.TTRSS:
				m_ttrss_revealer.set_reveal_child(true);
				break;

			case Backend.OWNCLOUD:
				m_owncloud_revealer.set_reveal_child(true);
				break;
		}

		m_need_htaccess = true;
	}


	public void write_login_data()
	{
		logger.print(LogMessage.DEBUG, "write login data");
		var backend = Backend.NONE;

		switch(m_comboBox.get_active())
		{
			case Backend.TTRSS:
				backend = Backend.TTRSS;
				settings_ttrss.set_string("url", m_ttrss_url_entry.get_text());
				settings_ttrss.set_string("username", m_ttrss_user_entry.get_text());
				var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "URL", Secret.SchemaAttributeType.STRING,
							                      "Username", Secret.SchemaAttributeType.STRING);
				var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
				attributes["URL"] = m_ttrss_url_entry.get_text();
				attributes["Username"] = m_ttrss_user_entry.get_text();
				try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_ttrss_password_entry.get_text(), null);}
				catch(GLib.Error e){}
				if(m_need_htaccess)
				{
					settings_ttrss.set_string("htaccess-username", m_ttrss_auth_user_entry.get_text());
					var pwAuthSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
								            			  "URL", Secret.SchemaAttributeType.STRING,
								                		  "Username", Secret.SchemaAttributeType.STRING,
														  "htaccess", Secret.SchemaAttributeType.BOOLEAN);
					var authAttributes = new GLib.HashTable<string,string>(str_hash, str_equal);
					authAttributes["URL"] = m_ttrss_url_entry.get_text();
					authAttributes["Username"] = m_ttrss_auth_user_entry.get_text();
					authAttributes["htaccess"] = "true";
					try{Secret.password_storev_sync(pwAuthSchema, authAttributes, Secret.COLLECTION_DEFAULT, "Feedserver htaccess Authentication", m_ttrss_auth_pw_entry.get_text(), null);}
					catch(GLib.Error e){}
				}
				break;

			case Backend.FEEDLY:
				backend = Backend.FEEDLY;
				loadLoginPage(OAuth.FEEDLY);
				return;

			case Backend.OWNCLOUD:
				backend = Backend.OWNCLOUD;
				settings_owncloud.set_string("url", m_owncloud_url_entry.get_text());
				settings_owncloud.set_string("username", m_owncloud_user_entry.get_text());
				var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "URL", Secret.SchemaAttributeType.STRING,
							                      "Username", Secret.SchemaAttributeType.STRING);
				var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
				attributes["URL"] = m_owncloud_url_entry.get_text();
				attributes["Username"] = m_owncloud_user_entry.get_text();
				try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_owncloud_password_entry.get_text(), null);}
				catch(GLib.Error e){}
				if(m_need_htaccess)
				{
					settings_owncloud.set_string("htaccess-username", m_owncloud_auth_user_entry.get_text());
					var pwAuthSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
								            			  "URL", Secret.SchemaAttributeType.STRING,
								            			  "Username", Secret.SchemaAttributeType.STRING,
														  "htaccess", Secret.SchemaAttributeType.BOOLEAN);
					var authAttributes = new GLib.HashTable<string,string>(str_hash, str_equal);
					authAttributes["URL"] = m_owncloud_url_entry.get_text();
					authAttributes["Username"] = m_owncloud_auth_user_entry.get_text();
					authAttributes["htaccess"] = "true";
					try{Secret.password_storev_sync(pwAuthSchema, authAttributes, Secret.COLLECTION_DEFAULT, "Feedserver htaccess Authentication", m_owncloud_auth_pw_entry.get_text(), null);}
					catch(GLib.Error e){}
				}
				break;
			case Backend.INOREADER:
				backend = Backend.INOREADER;
				settings_inoreader.set_string("username", m_inoreader_user_entry.get_text());
				var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "Apikey", Secret.SchemaAttributeType.STRING,
							                      "Apisecret", Secret.SchemaAttributeType.STRING,
							                      "Username", Secret.SchemaAttributeType.STRING);
				var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
				attributes["Apikey"] = InoReaderSecret.apikey;
				attributes["Apisecret"] = InoReaderSecret.apitoken;
				attributes["Username"] = m_inoreader_user_entry.get_text();
				try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_inoreader_password_entry.get_text(), null);}
				catch(GLib.Error e){}
				break;
		}

		LoginResponse status = feedDaemon_interface.login(backend);
		logger.print(LogMessage.DEBUG, "LoginPage: status = " + status.to_string());
		if(status == LoginResponse.SUCCESS)
		{
			submit_data();
			return;
		}

		loginError(status);
	}
}
