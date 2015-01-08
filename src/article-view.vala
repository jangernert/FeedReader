/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * article-view.vala
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

public class articleView : Gtk.Stack {

	private Gtk.Label m_title;
	private WebKit.WebView m_view;
	private Gtk.ScrolledWindow m_scroll;
	private Gtk.Box m_box;
	private Gtk.Spinner m_spinner;
	private bool m_open_external;
	private int m_load_ongoing;

	public articleView () {
		m_load_ongoing = 0;
		m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		m_title = new Gtk.Label("");
		m_title.set_size_request(0, 40);
		m_title.set_line_wrap(true);
		m_title.set_line_wrap_mode(Pango.WrapMode.WORD);
		
		
		m_view = new WebKit.WebView();
		m_view.load_changed.connect(open_link);
		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.set_size_request(400, 500);
		m_scroll.add(m_view);

		m_box.pack_start(m_title, false, false, 0);
		m_box.pack_start(m_scroll, true, true, 0);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("emptyView");

		m_spinner = new Gtk.Spinner();
		this.add_named(emptyView, "empty");
		this.add_named(m_box, "view");
		this.add_named(m_spinner, "spinner");
		
		this.set_visible_child_name("empty");
		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
	}


	public void fillContent(string articleID)
	{
		this.set_visible_child_name("spinner");
		m_spinner.start();
		string html = "", title = "", author = "", url = "";
		string feedID = "0";
		
		dataBase.read_article(articleID, out feedID, out title, out author, out url, out html, null);
		if(author == "") author = "not available";
		m_title.set_text("<big><b><a href=\"" + url.replace("&","&amp;") + "\" title=\"Author: " + author.replace("&","&amp;") + "\">" + title.replace("&","&amp;") + "</a></b></big>");
		m_title.set_use_markup (true);
		this.show_all();
		m_open_external = false;
		m_load_ongoing = 0;
		m_view.load_html(html, null);
		this.set_visible_child_name("view");
	}

	public void clearContent()
	{
		this.set_visible_child_name("empty");
	}

	public void open_link(WebKit.LoadEvent load_event)
	{
		m_load_ongoing++;
		
		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				if(m_open_external)
				{
					try{Gtk.show_uri(Gdk.Screen.get_default(), m_view.get_uri(), Gdk.CURRENT_TIME);}
					catch(GLib.Error e){ warning("could not open the link in an external browser\n%s\n", e.message); }
					m_view.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				break;	
			case WebKit.LoadEvent.FINISHED:
				if(m_load_ongoing >= 3){
					m_open_external = true;
				}
				break;
		}
	}
}
