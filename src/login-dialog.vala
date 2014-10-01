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
	public signal void submit_data();

	public loginDialog (Gtk.Window window, string error_message = "") {	
		this.title = "Login Data";
		this.border_width = 5;
		this.set_transient_for(window);
		set_default_size (500, 300);

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

		var url_label = new Gtk.Label(_("tt-rss URL:"));
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		url_label.set_alignment(1.0f, 0.5f);
		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);
		
		m_url_entry = new Gtk.Entry();
		m_user_entry = new Gtk.Entry();
		m_password_entry = new Gtk.Entry();

		m_url_entry.activate.connect(on_enter);
		m_user_entry.activate.connect(on_enter);
		m_password_entry.activate.connect(on_enter);

		m_url_entry.set_text(dataBase.read_login("url"));
		m_user_entry.set_text(dataBase.read_login("user"));
		m_password_entry.set_text(dataBase.read_login("password"));
		m_password_entry.set_invisible_char('*');
		m_password_entry.set_visibility(false);
		

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		
		grid.attach(url_label, 0, 0, 1, 1);
		grid.attach(m_url_entry, 1, 0, 1, 1);
		grid.attach(user_label, 0, 1, 1, 1);
		grid.attach(m_user_entry, 1, 1, 1, 1);
		grid.attach(password_label, 0, 2, 1, 1);
		grid.attach(m_password_entry, 1, 2, 1, 1);

		var content = get_content_area ();
		var center = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
		center.set_padding(20, 20, 20, 20);
		center.add(grid);
		error_box.pack_start(center, true, true, 0);
		content.add(error_box);

		add_button("Cancel", Gtk.ResponseType.CANCEL);
		m_okay_button = add_button("OK", Gtk.ResponseType.APPLY);
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
		if(url != ""){
			if(!url.has_suffix("/"))
				url = url + "/";

			if(!url.has_suffix("/api/"))
				url = url + "api/";

			if(!url.has_prefix("http://"))
					url = "http://" + url;
		}


		//stdout.printf("%s\n%s\n%s\n", url, m_user_entry.get_text(), m_password_entry.get_text());
		dataBase.write_login("url",url);
		dataBase.write_login("user",  m_user_entry.get_text());
		//db.write_login("password", m_password_entry.get_text());

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
