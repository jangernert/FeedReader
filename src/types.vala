/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * article.vala
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

public class feed : GLib.Object {

	public string m_feedID { get; private set; }
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	public bool m_hasIcon { get; private set; }
	public int m_unread { get; private set; }
	public string m_categorieID { get; private set; }
	
	public feed (string feedID, string title, string url, int hasIcon, int unread, string categorieID) {
		m_feedID = feedID;
		m_title = title;
		m_url = url;
		m_unread = unread;
		m_categorieID = categorieID;
		
		if(hasIcon == 0)			m_hasIcon = false;
		else if(hasIcon == 1)		m_hasIcon = true;
	}
}


public class category : GLib.Object {

	public string m_categorieID { get; private set; }
	public string m_title { get; private set; }
	public int m_unread_count { get; private set; }
	public int m_orderID { get; private set; }
	public string m_parent { get; private set; }
	public int m_level { get; private set; }

	public category (string categorieID, string title, int unread_count, int orderID, string parent, int level) {
		m_categorieID = categorieID;
		m_title = title;
		m_unread_count = unread_count;
		m_orderID = orderID;
		m_parent = parent;
		m_level = level;
	}
}


public class headline : GLib.Object {

	public string m_articleID { get; private set; }
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	public string m_feedID { get; private set; }
	public int m_unread { get; private set; }
	public int m_marked { get; private set; }
	

	
	public headline (string articleID, string title, string url, string feedID, int unread, int marked) {
		m_articleID = articleID;
		m_title = title;
		m_url = url;
		m_feedID = feedID;
		m_unread = unread;
		m_marked = marked;
	}
}


