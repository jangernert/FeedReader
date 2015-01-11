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
	ttrss_interface m_ttrss;
	FeedlyAPI m_feedly;
	int m_type;

	public feed_server(int type)
	{
		m_type = type;
		
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss = new ttrss_interface();
				break;
				
			case TYPE_FEEDLY:
				m_feedly = FeedlyAPI.get_api_with_token();
				break;
		}
	}
	
	public int login()
	{
		switch(m_type)
		{
			case TYPE_NONE:
				return LOGIN_NO_BACKEND;
				break;
				
			case TYPE_TTRSS:
				return m_ttrss.login();
				break;
				
			case TYPE_FEEDLY:
				return LOGIN_SUCCESS;
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
				yield m_ttrss.getHeadlines();
				yield m_ttrss.updateHeadlines();
				break;
				
			case TYPE_FEEDLY:
				yield m_feedly.getCategories();
				yield m_feedly.getFeeds();
				//yield m_feedly.getArticles();
				break;
		}
	}
	
	public void setArticleIsRead(string articleID, int read)
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss.updateArticleUnread.begin(int.parse(articleID), read, (obj, res) => {
					m_ttrss.updateArticleUnread.end(res);
				});
				break;
				
			case TYPE_FEEDLY:
				m_feedly.mark_as_read(articleID, "entries", read);
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

