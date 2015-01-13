/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * articlerow.vala
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

public class articleRow : baseRow {

	private int m_is_unread;
	private int m_marked;
	private string m_url;
	private string m_name;
	private Gtk.Image m_marked_icon;
	private Gtk.Image m_unmarked_icon;
	private Gtk.Image m_unread_icon;
	private Gtk.Image m_read_icon;
	private Gtk.EventBox m_unread_eventbox;
	private Gtk.EventBox m_marked_eventbox;
	private bool m_just_clicked;
	public string m_articleID { get; private set; }
	public string m_feedID { get; private set; }
	public signal void updateFeedList();

	public articleRow (string aritcleName, int unread, string iconname, string url, string feedID, string articleID, int marked)
	{
		m_marked = marked;
		m_name = aritcleName;
		m_articleID = articleID;
		m_feedID = feedID;
		m_url = url;
		m_is_unread = unread;
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(500);
		
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 100);

		int spacing = 8;
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";

		string feed_icon_name = icon_path + iconname.replace("/", "_").replace(".", "_") + ".ico";
		Gdk.Pixbuf tmp_icon;
		try{
			if(FileUtils.test(feed_icon_name, GLib.FileTest.EXISTS))
			{
				tmp_icon = new Gdk.Pixbuf.from_file(feed_icon_name);
			}
			else
			{
				tmp_icon = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/rss24.png");
			}
			scale_pixbuf(ref tmp_icon, 24);
			m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
			spacing = 0;
		}catch(GLib.Error e){}


		this.enter_notify_event.connect(() => {
			stdout.printf("%s\n", m_name);
			return false;
		});

		
		m_label = new Gtk.Label(aritcleName);
		m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_label.set_line_wrap(true);
		m_label.set_lines(2);
		if(m_is_unread == STATUS_UNREAD)
			m_label.get_style_context().add_class("headline-unread-label");
		else
			m_label.get_style_context().add_class("headline-read-label");
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

		m_just_clicked = false;
			
		var icon_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		icon_box.set_size_request(24, 0);
			
		m_marked_icon = new Gtk.Image.from_icon_name("starred", Gtk.IconSize.SMALL_TOOLBAR);
		m_unread_icon = new Gtk.Image.from_icon_name("mail-unread", Gtk.IconSize.SMALL_TOOLBAR);
		m_unmarked_icon = new Gtk.Image.from_icon_name("non-starred", Gtk.IconSize.SMALL_TOOLBAR);
		m_read_icon = new Gtk.Image.from_icon_name("user-offline", Gtk.IconSize.SMALL_TOOLBAR);	

		m_unread_eventbox = new Gtk.EventBox();
		m_unread_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_unread_eventbox.set_size_request(16, 16);
		if(m_is_unread == STATUS_UNREAD)
			m_unread_eventbox.add(m_unread_icon);
		else
			m_unread_eventbox.add(m_read_icon);

		m_unread_eventbox.enter_notify_event.connect(() => {unreadIconEnter(); return true;});
		m_unread_eventbox.leave_notify_event.connect(() => {unreadIconLeave(); return true;});
		m_unread_eventbox.button_press_event.connect(() => {unreadIconCliced(); return true;});

			
		m_marked_eventbox = new Gtk.EventBox();
		m_marked_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_marked_eventbox.set_size_request(16, 16);
		if(m_marked == STATUS_MARKED)
			m_marked_eventbox.add(m_marked_icon);
		else
			m_marked_eventbox.add(m_unmarked_icon);
			
		m_marked_eventbox.enter_notify_event.connect(() => {markedIconEnter(); return true;});
		m_marked_eventbox.leave_notify_event.connect(() => {markedIconLeave(); return true;});
		m_marked_eventbox.button_press_event.connect(() => {markedIconCliced(); return true;});

			

		icon_box.pack_start(m_icon, true, true, 0);
		icon_box.pack_end(m_unread_eventbox, false, false, 10);
		icon_box.pack_end(m_marked_eventbox, false, false, 0);
			
		var Article = dataBase.read_article(m_articleID);


		var body_label = new Gtk.Label(Article.m_preview);
		body_label.get_style_context().add_class("grey-label");
		body_label.set_alignment(0, 0);
		body_label.set_ellipsize (Pango.EllipsizeMode.END);
		body_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		body_label.set_line_wrap(true);
		body_label.set_lines(3);

		m_spacer = new Gtk.Label("");
		m_spacer.set_size_request(15, 0);
			
			
			
		var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		text_box.pack_start(m_label, true, true, 6);
		text_box.pack_end(body_label, true, true, 6);
			
		m_box.pack_start(icon_box, false, false, 8);
		m_box.pack_start(text_box, true, true, 0);
		m_box.pack_start(m_spacer, true, true, 0);

		var seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 2);
		seperator_box.pack_start(m_box, true, true, 0);
		seperator_box.pack_start(separator, false, false, 0);
		m_revealer.add(seperator_box);
		
		m_revealer.set_reveal_child(false);
		m_isRevealed = false;
		this.add(m_revealer);
		this.show_all();
	}


	private void unreadIconCliced()
	{
		if(m_just_clicked)
			unreadIconEnter();
		m_just_clicked = true;
		switch(m_is_unread)
		{
			case STATUS_READ:
				updateUnread(STATUS_UNREAD);
				break;
			case STATUS_UNREAD:
				updateUnread(STATUS_READ);
				break;
		}
		feedDaemon_interface.changeUnread(m_articleID, m_is_unread);
		
		dataBase.update_article.begin(m_articleID, "unread", m_is_unread, (obj, res) => {
			dataBase.update_article.end(res);
		});
		dataBase.change_unread.begin(m_feedID, m_is_unread, (obj, res) => {
			dataBase.change_unread.end(res);
			updateFeedList();
		});
	}

	private void unreadIconEnter()
	{
		if(m_is_unread == STATUS_READ){
			m_unread_eventbox.remove(m_read_icon);
			m_unread_eventbox.add(m_unread_icon);
		}
		else{
			m_unread_eventbox.remove(m_unread_icon);
			m_unread_eventbox.add(m_read_icon);
		}
		this.show_all();
	}


	private void unreadIconLeave()
	{
		if(!m_just_clicked){
			if(m_is_unread == STATUS_READ){
				m_unread_eventbox.remove(m_unread_icon);
				m_unread_eventbox.add(m_read_icon);
			}
			else{
				m_unread_eventbox.remove(m_read_icon);
				m_unread_eventbox.add(m_unread_icon);
			}
		}
		m_just_clicked = false;
		this.show_all();
	}

	public void updateUnread(int unread)
	{
		if(m_is_unread != unread)
		{
			m_is_unread = unread;
			if(m_is_unread == STATUS_UNREAD)
			{
				m_label.get_style_context().remove_class("headline-read-label");
				m_label.get_style_context().add_class("headline-unread-label");
			}
			else
			{
				m_label.get_style_context().remove_class("headline-unread-label");
				m_label.get_style_context().add_class("headline-read-label");
			}
		}
	}

	public void removeUnreadIcon()
	{
		m_unread_eventbox.remove(m_unread_icon);
		m_unread_eventbox.add(m_read_icon);
		this.show_all();
	}


	private void markedIconCliced()
	{
		m_just_clicked = true;
		switch(m_marked)
		{
			case STATUS_MARKED:
				updateMarked(STATUS_UNMARKED);
				break;
			
			case STATUS_UNMARKED:
				updateMarked(STATUS_MARKED);
				break;
		}
		
		feedDaemon_interface.changeMarked(m_articleID, m_marked);
		
		dataBase.update_article.begin(m_articleID, "marked", m_marked, (obj, res) => {
			dataBase.update_article.end(res);
		});
	}

	private void markedIconEnter()
	{
		if(m_marked == STATUS_UNMARKED){
			m_marked_eventbox.remove(m_unmarked_icon);
			m_marked_eventbox.add(m_marked_icon);
		}
		else if (m_marked == STATUS_MARKED){
			m_marked_eventbox.remove(m_marked_icon);
			m_marked_eventbox.add(m_unmarked_icon);
		}
		this.show_all();
	}


	private void markedIconLeave()
	{
		if(!m_just_clicked){
			if(m_marked == STATUS_UNMARKED){
				m_marked_eventbox.remove(m_marked_icon);
				m_marked_eventbox.add(m_unmarked_icon);
			}
			else if(m_marked == STATUS_MARKED){
				m_marked_eventbox.remove(m_unmarked_icon);
				m_marked_eventbox.add(m_marked_icon);
			}
			this.show_all();
		}
		m_just_clicked = false;
	}

	public void updateMarked(int marked)
	{
		m_marked = marked;	
	}

	public bool isUnread()
	{
		if(m_is_unread == STATUS_UNREAD)
			return true;
			
		return false;
	}
	
	public string getName()
	{
		return m_name;
	}

 	 
}
