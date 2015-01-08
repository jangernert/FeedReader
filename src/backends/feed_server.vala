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
	
	public bool login()
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				return m_ttrss.login(null);
				break;
				
			case TYPE_FEEDLY:
				return true;
		}
		return false;
	}
	
	public async void sync_content()
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				yield m_ttrss.getCategories();
				yield m_ttrss.getFeeds();
				yield m_ttrss.getHeadlines();
				yield m_ttrss.updateHeadlines(300);
				break;
				
			case TYPE_FEEDLY:
				yield m_feedly.getCategories();
				yield m_feedly.getFeeds();
				break;
		}
	}
	
	public void setArticleIsRead(string articleID, bool read)
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss.updateArticleUnread.begin(articleID, read, (obj, res) => {
					m_ttrss.updateArticleUnread.end(res);
				});
				break;
				
			case TYPE_FEEDLY:
				
				break;
		}
	}
	
	public void setArticleIsMarked(string articleID, bool marked)
	{
		switch(m_type)
		{
			case TYPE_TTRSS:
				m_ttrss.updateArticleMarked.begin(articleID, marked, (obj, res) => {
					m_ttrss.updateArticleMarked.end(res);
				});
				break;
				
			case TYPE_FEEDLY:
				
				break;
		}
	}

}

