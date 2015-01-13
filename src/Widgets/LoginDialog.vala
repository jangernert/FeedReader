/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * login-dialog.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class loginDialog : Gtk.Dialog {

	private Gtk.Widget m_okay_button;
	private Gtk.Entry m_ttrss_url_entry;
	private Gtk.Entry m_ttrss_user_entry;
	private Gtk.Entry m_ttrss_password_entry;
	private Gtk.Entry m_owncloud_url_entry;
	private Gtk.Entry m_owncloud_user_entry;
	private Gtk.Entry m_owncloud_password_entry;
	private Gtk.ComboBox m_comboBox;
	private Gtk.Stack m_login_details;
	private string m_feedly_api_code;
	private string[] m_account_types;
	public signal void submit_data();

	public loginDialog(Gtk.Window window, int ErrorCode) {
		this.title = "Login Data";
		this.border_width = 5;
		GLib.Object (use_header_bar: 1);
		this.set_modal(true);
		this.set_transient_for(window);
		set_default_size (500, 300);
		
		m_account_types = {_("Tiny Tiny RSS"), _("Feedly"), _("OwnCloud")};
		
		var error_bar = new Gtk.InfoBar();
		var error_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var error_content = error_bar.get_content_area();
		error_bar.set_message_type(Gtk.MessageType.ERROR);		
		error_bar.set_show_close_button(true);
		
		error_bar.response.connect((response_id) => {
			if(response_id == Gtk.ResponseType.CLOSE) {
					error_bar.set_visible(false);
			}
		});
		
		switch(ErrorCode)
		{
			case LOGIN_SUCCESS:
			case LOGIN_FIRST_TRY:
				break;
			case LOGIN_NO_BACKEND:
				error_content.add(new Gtk.Label(_("Please select a service first")));
				break;
			case LOGIN_MISSING_USER:
				error_content.add(new Gtk.Label(_("Please enter a valid username")));
				break;
			case LOGIN_MISSING_PASSWD:
				error_content.add(new Gtk.Label(_("Please enter a valid password")));
				break;
			case LOGIN_MISSING_URL:
				error_content.add(new Gtk.Label(_("Please enter a valid URL")));
				break;
			case LOGIN_ALL_EMPTY:
				error_content.add(new Gtk.Label(_("Please enter your Login details")));
				break;
			case LOGIN_UNKNOWN_ERROR:
				error_content.add(new Gtk.Label(_("Sorry, something went wrong.")));
				break;
		}

		if(ErrorCode != LOGIN_SUCCESS && ErrorCode != LOGIN_FIRST_TRY)
			error_box.pack_start(error_bar, false, false, 0);
		

		
		
		var comboBox_label = new Gtk.Label(_("RSS Type:"));
		comboBox_label.set_alignment(0.0f, 0.5f);
		
		
		var liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter ttrss;
		liststore.append(out ttrss);
		liststore.set(ttrss, 0, m_account_types[TYPE_TTRSS]);
		Gtk.TreeIter feedly;
		liststore.append(out feedly);
		liststore.set(feedly, 0, m_account_types[TYPE_FEEDLY]);
		Gtk.TreeIter ownCloud;
		liststore.append(out ownCloud);
		liststore.set(ownCloud, 0, m_account_types[TYPE_OWNCLOUD]);
		m_comboBox = new Gtk.ComboBox.with_model(liststore);
		
		Gtk.CellRendererText renderer = new Gtk.CellRendererText();
		m_comboBox.pack_start (renderer, false);
		m_comboBox.add_attribute(renderer, "text", 0);
		
		m_login_details = new Gtk.Stack();
		m_login_details.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_login_details.set_transition_duration(100);
		
		var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		hbox.pack_start(comboBox_label, false, false);
		hbox.pack_start(m_comboBox, true, true);
		vbox.pack_start(hbox);
		vbox.pack_start(m_login_details);
		var center = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
		center.set_padding(20, 20, 20, 20);
		center.add(vbox);
		error_box.pack_start(center, true, true, 0);
		var content = get_content_area();
		content.add(error_box);
		
		m_comboBox.changed.connect(() => {
			if(m_comboBox.get_active() != -1) {
				switch(m_comboBox.get_active())
				{
					case TYPE_NONE:
						m_login_details.set_visible_child_name("none");
						break;
					case TYPE_TTRSS:
						m_login_details.set_visible_child_name("ttrss");
						break;
					case TYPE_FEEDLY:
						m_login_details.set_visible_child_name("feedly");
						break;
					case TYPE_OWNCLOUD:
						m_login_details.set_visible_child_name("owncloud");
						break;
				}
			}
		});
		
		var nothing_selected = new Gtk.Label(_("Please tell us where your feeds are stored"));
		m_login_details.add_named(nothing_selected, "none");
		
		setup_ttrss_login();
		setup_feedly_login();
		setup_owncloud_login();
		
		
		

		add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
		m_okay_button = add_button("Login", Gtk.ResponseType.APPLY);
		m_okay_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		this.response.connect(on_response);
		this.show_all();
		
		switch(feedreader_settings.get_enum("account-type"))
		{
			case TYPE_NONE:
				m_comboBox.set_active(TYPE_NONE);
				m_login_details.set_visible_child_name("none");
				break;
			case TYPE_TTRSS:
				m_comboBox.set_active(TYPE_TTRSS);
				m_login_details.set_visible_child_name("ttrss");
				break;
			case TYPE_FEEDLY:
				m_comboBox.set_active(TYPE_FEEDLY);
				m_login_details.set_visible_child_name("feedly");
				break;
			case TYPE_OWNCLOUD:
				m_comboBox.set_active(TYPE_OWNCLOUD);
				m_login_details.set_visible_child_name("owncloud");
				break;
		}
		
	}
	
	private void setup_ttrss_login()
	{
		var ttrss_url_label = new Gtk.Label(_("tt-rss URL:"));
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

		m_ttrss_url_entry.activate.connect(on_enter);
		m_ttrss_user_entry.activate.connect(on_enter);
		m_ttrss_password_entry.activate.connect(on_enter);
		
		if(feedreader_settings.get_enum("account-type") == TYPE_TTRSS)
		{
			string url = feedreader_settings.get_string("url");
			string username = feedreader_settings.get_string("username");
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
		
		m_ttrss_password_entry.set_invisible_char('*');
		m_ttrss_password_entry.set_visibility(false);
		
		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		
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
		ttrss_box.pack_start(ttrss_logo, false, false, 20);
		ttrss_box.pack_start(grid);
		
		m_login_details.add_named(ttrss_box, "ttrss");
	}
	
	
	private void setup_feedly_login()
	{
		var tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/feedly.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var feedly_logo = new Gtk.Image.from_pixbuf(tmp_logo);
		
		var login_button =  new Gtk.Button.with_label("Login");
		var alignment = new Gtk.Alignment (0.50f, 0.25f, 1.0f, 0.5f);
		alignment.right_padding = 20;
		alignment.left_padding = 20;
		alignment.add (login_button);
		
		login_button.clicked.connect(() => {
			var dialog = new WebLogin(this, m_account_types[TYPE_FEEDLY], TYPE_FEEDLY);
			dialog.auth_code.connect((code) => {
				m_feedly_api_code = code;
				on_enter();
			});
		});
		
		var feedly_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		feedly_box.pack_start(feedly_logo, false, false, 20);
		feedly_box.pack_start(alignment, true, true, 0);
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

		m_owncloud_url_entry.activate.connect(on_enter);
		m_owncloud_user_entry.activate.connect(on_enter);
		m_owncloud_password_entry.activate.connect(on_enter);
		
		if(feedreader_settings.get_enum("account-type") == TYPE_OWNCLOUD)
		{
			string url = feedreader_settings.get_string("url");
			string username = feedreader_settings.get_string("username");
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
		
		m_owncloud_password_entry.set_invisible_char('*');
		m_owncloud_password_entry.set_visibility(false);
		
		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		
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
		owncloud_box.pack_start(owncloud_logo, false, false, 20);
		owncloud_box.pack_start(grid);
		
		m_login_details.add_named(owncloud_box, "owncloud");
	}


	private void on_response (Gtk.Dialog source, int response_id) {
		switch (response_id) {
		case Gtk.ResponseType.APPLY:
			on_enter();
			break;
		case Gtk.ResponseType.CANCEL:
			destroy();
			break;
		}
	}

	private void on_enter()
	{
		write_login_data();
		destroy();
	}

	private void write_login_data()
	{
		print("write login data\n");
		if(m_comboBox.get_active() != -1) {
			switch(m_comboBox.get_active())
			{
				case TYPE_TTRSS:
					feedreader_settings.set_enum("account-type", TYPE_TTRSS);
					string url = m_ttrss_url_entry.get_text();
					feedreader_settings.set_string("url", url);
					feedreader_settings.set_string("username", m_ttrss_user_entry.get_text());
					var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
								                      "URL", Secret.SchemaAttributeType.STRING,
								                      "Username", Secret.SchemaAttributeType.STRING);
					var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
					attributes["URL"] = url;
					attributes["Username"] = m_ttrss_user_entry.get_text();
					try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_ttrss_password_entry.get_text(), null);}
					catch(GLib.Error e){}
					break;
					
				case TYPE_FEEDLY:
					print("write type feedly\n");
					feedreader_settings.set_enum("account-type", TYPE_FEEDLY);
					feedreader_settings.set_string("feedly-api-code", m_feedly_api_code);
					break;
					
				case TYPE_OWNCLOUD:
					feedreader_settings.set_enum("account-type", TYPE_OWNCLOUD);
					break;
			}
		}
		
		submit_data();
	}

}
