/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * feed_server.vala
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

public class feed_server : GLib.Object {
	private ttrss_interface m_ttrss;
	private FeedlyAPI m_feedly;
	private int m_type;

	public feed_server(int type)
	{
		m_type = type;
		
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss = new ttrss_interface();
				break;
				
			case TYPE_FEEDLY:
				m_feedly = new FeedlyAPI();
				break;
		}
	}
	
	public int getType()
	{
		return m_type;
	} 
	
	public int login()
	{
		switch(m_type)
		{
			case TYPE_NONE:
				return LOGIN_NO_BACKEND;
				
			case TYPE_TTRSS:
				return m_ttrss.login();
				
			case TYPE_FEEDLY:
				return m_feedly.login();
		}
		return LOGIN_UNKNOWN_ERROR;
	}
	
	public async void sync_content()
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				yield m_ttrss.getCategories();
				yield m_ttrss.getFeeds();
				yield m_ttrss.getArticles();
				yield m_ttrss.updateArticles();
				break;
				
			case TYPE_FEEDLY:
				yield m_feedly.getCategories();
				yield m_feedly.getFeeds();
				yield m_feedly.getArticles();
				break;
		}
	}
	
	public async void setArticleIsRead(string articleID, int read)
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				yield m_ttrss.updateArticleUnread(int.parse(articleID), read);
				break;
				
			case TYPE_FEEDLY:
				yield m_feedly.mark_as_read(articleID, "entries", read);
				break;
		}
	}
	
	public void setArticleIsMarked(string articleID, int marked)
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss.updateArticleMarked.begin(int.parse(articleID), marked, (obj, res) => {
					m_ttrss.updateArticleMarked.end(res);
				});
				break;
				
			case TYPE_FEEDLY:
				
				break;
		}
	}

}

