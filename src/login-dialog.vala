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
	private Gtk.Entry m_url_entry;
	private Gtk.Entry m_user_entry;
	private Gtk.Entry m_password_entry;
	private Gtk.ComboBox m_comboBox;
	private string[] account_types;
	public signal void submit_data();

	public loginDialog (Gtk.Window window, string error_message = "") {	
		this.title = "Login Data";
		this.border_width = 5;
		GLib.Object (use_header_bar: 1);
		this.set_modal(true);
		this.set_transient_for(window);
		set_default_size (500, 300);
		
		account_types = {"Tiny Tiny RSS", "Feedly", "OwnCloud"};

		var error_bar = new Gtk.InfoBar();
		error_bar.set_message_type(Gtk.MessageType.ERROR);		
		error_bar.set_show_close_button(true);
		var error_content = error_bar.get_content_area();
		error_content.add(new Gtk.Label(error_message));		
		var error_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		if(error_message != "")
			error_box.pack_start(error_bar, false, false, 0);
		

		error_bar.response.connect((response_id) => {
			switch (response_id) {
			case Gtk.ResponseType.CLOSE:
				error_bar.set_visible(false);
				break;
		}
		});
		
		
		
		var comboBox_label = new Gtk.Label(_("RSS Type:"));
		var url_label = new Gtk.Label(_("tt-rss URL:"));
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		comboBox_label.set_alignment(0.0f, 0.5f);
		url_label.set_alignment(1.0f, 0.5f);
		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);
		
		m_url_entry = new Gtk.Entry();
		m_user_entry = new Gtk.Entry();
		m_password_entry = new Gtk.Entry();

		m_url_entry.activate.connect(on_enter);
		m_user_entry.activate.connect(on_enter);
		m_password_entry.activate.connect(on_enter);

		string url = feedreader_settings.get_string("url");
		string username = feedreader_settings.get_string("username");
		m_url_entry.set_text(url);
		m_user_entry.set_text(username);
		
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = url;
		attributes["Username"] = username;

		string passwd = "";
		try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}
		
		m_password_entry.set_text(passwd);
		m_password_entry.set_invisible_char('*');
		m_password_entry.set_visibility(false);
		

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		
		Gdk.Pixbuf tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/ttrss.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var ttrss_logo = new Gtk.Image.from_pixbuf(tmp_logo);
		
		tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/feedly.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var feedly_logo = new Gtk.Image.from_pixbuf(tmp_logo);
		
		tmp_logo = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/owncloud.png");
		tmp_logo = tmp_logo.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
		var owncloud_logo = new Gtk.Image.from_pixbuf(tmp_logo);
		
		grid.attach(url_label, 0, 0, 1, 1);
		grid.attach(m_url_entry, 1, 0, 1, 1);
		grid.attach(user_label, 0, 1, 1, 1);
		grid.attach(m_user_entry, 1, 1, 1, 1);
		grid.attach(password_label, 0, 2, 1, 1);
		grid.attach(m_password_entry, 1, 2, 1, 1);
		
		var liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter ttrss;
		liststore.append(out ttrss);
		liststore.set(ttrss, 0, account_types[0]);
		Gtk.TreeIter feedly;
		liststore.append(out feedly);
		liststore.set(feedly, 0, account_types[1]);
		Gtk.TreeIter ownCloud;
		liststore.append(out ownCloud);
		liststore.set(ownCloud, 0, account_types[2]);
		m_comboBox = new Gtk.ComboBox.with_model(liststore);
		
		Gtk.CellRendererText renderer = new Gtk.CellRendererText();
		m_comboBox.pack_start (renderer, false);
		m_comboBox.add_attribute(renderer, "text", 0);
		m_comboBox.active = 0;
		
		var login_details = new Gtk.Stack();
		login_details.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		login_details.set_transition_duration(100);
		
		var ttrss_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		ttrss_box.pack_start(ttrss_logo, false, false, 20);
		ttrss_box.pack_start(grid);
		
		var feedly_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		feedly_box.pack_start(feedly_logo, false, false, 20);
		
		var owncloud_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		owncloud_box.pack_start(owncloud_logo, false, false, 20);
		
		login_details.add_named(ttrss_box, "ttrss");
		login_details.add_named(feedly_box, "feedly");
		login_details.add_named(owncloud_box, "owncloud");
		
		var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		hbox.pack_start(comboBox_label, false, false);
		hbox.pack_start(m_comboBox, true, true);
		vbox.pack_start(hbox);
		vbox.pack_start(login_details);
		var center = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
		center.set_padding(20, 20, 20, 20);
		center.add(vbox);
		error_box.pack_start(center, true, true, 0);
		var content = get_content_area ();
		content.add(error_box);
		
		m_comboBox.changed.connect(() => {
			if(m_comboBox.get_active() != -1) {
				print ("You chose " + account_types[m_comboBox.get_active()] +"\n");
				switch(m_comboBox.get_active()+1)
				{
					case TYPE_TTRSS:
						login_details.set_visible_child_name("ttrss");
						feedreader_settings.set_enum("account-type", TYPE_TTRSS);
						break;
					case TYPE_FEEDLY:
						login_details.set_visible_child_name("feedly");
						feedreader_settings.set_enum("account-type", TYPE_FEEDLY);
						break;
					case TYPE_OWNCLOUD:
						login_details.set_visible_child_name("owncloud");
						feedreader_settings.set_enum("account-type", TYPE_OWNCLOUD);
						break;
				}
			}
		});

		add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
		m_okay_button = add_button("Login", Gtk.ResponseType.APPLY);
		m_okay_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		this.response.connect(on_response);
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
		string url = m_url_entry.get_text();

		feedreader_settings.set_string("url", url);
		feedreader_settings.set_string("username", m_user_entry.get_text());

		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = url;
		attributes["Username"] = m_user_entry.get_text();

		try{Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", m_password_entry.get_text(), null);}
		catch(GLib.Error e){}
		submit_data();
	}

}
