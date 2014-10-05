/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * reader-headerbar.vala
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

public class readerHeaderbar : Gtk.HeaderBar {
	
	private Gtk.ToggleButton m_only_unread_button;
	private Gtk.ToggleButton m_only_marked_button;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	public bool m_only_unread { get; private set; }
	public bool m_only_marked { get; private set; }
	public signal void refresh();
	public signal void change_unread(bool only_unread);
	public signal void change_marked(bool only_marked);
	public signal void search_term(string searchTerm);


	public readerHeaderbar () {
		var only_unread_icon = new Gtk.Image.from_icon_name("object-inverse", Gtk.IconSize.LARGE_TOOLBAR);
		var only_marked_icon = new Gtk.Image.from_icon_name("help-about", Gtk.IconSize.LARGE_TOOLBAR);

		//if(dataBase.read_propertie("only_unread") == 1)	{m_only_unread = true;}
		//else											{m_only_unread = false; }
		
		m_only_unread = feedreader_settings.get_boolean("only-unread");

		//if(dataBase.read_propertie("only_marked") == 1)	{m_only_marked = true;}
		//else											{m_only_marked = false; }
	
		m_only_marked = feedreader_settings.get_boolean("only-marked");
		
		m_only_unread_button = new Gtk.ToggleButton();
		m_only_unread_button.add(only_unread_icon);
		m_only_unread_button.set_active(m_only_unread);

		m_only_marked_button = new Gtk.ToggleButton();
		m_only_marked_button.add(only_marked_icon);
		m_only_marked_button.set_active(m_only_marked);

		
		m_only_unread_button.toggled.connect (() => {
			if (m_only_unread_button.active) {
				m_only_unread = true;
				
			} else {
				m_only_unread = false;
			}
			change_unread(m_only_unread);
		});

		m_only_marked_button.toggled.connect (() => {
			if (m_only_marked_button.active) {
				m_only_marked = true;
				
			} else {
				m_only_marked = false;
			}
			change_marked(m_only_marked);
		});

		m_refresh_button = new UpdateButton("view-refresh");
		m_refresh_button.clicked.connect(() => {
			refresh();
		});
		
		m_search = new Gtk.SearchEntry();
		m_search.placeholder_text = "Search Aritlces...";
		m_search.search_changed.connect(() => {
			search_term(m_search.text);
		});
		
		
		var menu = new Gtk.Menu();
		var item_login = new Gtk.MenuItem.with_label("Change Login");
		var item_about = new Gtk.MenuItem.with_label("About");
		menu.add(item_login);
		menu.add(item_about);
		var menumodel = new GLib.Menu ();
		menumodel.append ("Change Login", "win.login");
		menumodel.append ("About", "win.about");

		

		var menubutton = new Gtk.MenuButton();
		menubutton.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
		menubutton.set_size_request(32, 32);
		menubutton.set_use_popover(true);
		menubutton.set_menu_model(menumodel);
		this.show_close_button = true;
		this.pack_end(menubutton);
		this.pack_end(m_search);
		this.pack_start(m_only_unread_button);
		this.pack_start(m_only_marked_button);
		this.pack_start(m_refresh_button);
	}

	public void setRefreshButton(bool status)
	{
		m_refresh_button.updating(status);
	}

}

