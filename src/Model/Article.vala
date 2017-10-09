//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.Article : GLib.Object {

	private string m_articleID;
	private string m_title;
	private string m_url;
	private string m_html;
	private string m_preview;
	private string m_feedID;
	private Gee.List<string> m_tags;
	private Gee.List<string> m_media;
	private string? m_author;
	private ArticleStatus m_unread;
	private ArticleStatus m_marked;
	private int m_sortID;
	private GLib.DateTime m_date;
	private string m_guidHash;
	private int m_lastModified;
	private int m_pos;

	private static GLib.Settings? gnome_settings;
	private static bool clock_12_hour = false;

	static construct
	{
		// Lookup the schema in a complicated way so we don't require users
		// to be running GNOME Shell
		var schema_source = SettingsSchemaSource.get_default();
		var schema = schema_source.lookup("org.gnome.desktop.interface", true);
		if(schema != null)
		{
			gnome_settings = new GLib.Settings.full(schema, null, null);
			clock_12_hour = gnome_settings.get_string("clock-format") == "12h";
			gnome_settings.changed["clock-format"].connect(() => {
				clock_12_hour = gnome_settings.get_string("clock-format") == "12h";
			});
		}
	}

	public Article (string articleID,
					string title,
					string url,
					string feedID,
					ArticleStatus unread,
					ArticleStatus marked,
					string html,
					string preview,
					string? author,
					GLib.DateTime date,
					int sortID = 0,
					Gee.List<string>? tags = null,
					Gee.List<string>? media = null,
					string guidHash = "",
					int lastModified = 0)
	{
		m_articleID = articleID;
		m_title = title;
		m_url = url;
		m_html = html;
		m_preview = preview;
		m_feedID = feedID;
		m_author = author;
		m_unread = unread;
		m_marked = marked;
		m_sortID = sortID;
		m_date = date;
		m_guidHash = guidHash;
		m_lastModified = lastModified;

		m_tags = tags == null ? Gee.List.empty<string>() : tags;
		m_media = media == null ? Gee.List.empty<string>() : media;
	}

	public string getArticleID()
	{
		return m_articleID;
	}

	public string getArticleFileName()
	{
		return GLib.Base64.encode(m_articleID.data);
	}

	public string getFeedFileName()
	{
		return GLib.Base64.encode(m_articleID.data);
	}

	public string getTitle()
	{
		return m_title;
	}

	public void setTitle(string title)
	{
		m_title = title;
	}

	public string getHTML()
	{
		return m_html;
	}

	public void setHTML(string html)
	{
		m_html = html;
	}

	public string getPreview()
	{
		return m_preview;
	}

	public void setPreview(string preview)
	{
		m_preview = preview;
	}

	public string? getAuthor()
	{
		return m_author;
	}

	public void setAuthor(string? author)
	{
		m_author = author;
	}

	public string getURL()
	{
		return m_url;
	}

	public void setURL(string url)
	{
		m_url = url;
	}

	public int getSortID()
	{
		return m_sortID;
	}

	public GLib.DateTime getDate()
	{
		return m_date;
	}

	public void SetDate(GLib.DateTime date)
	{
		m_date = date;
	}

	public string getDateNice(bool addTime = false)
	{
		var now = new GLib.DateTime.now_local();
		var now_year = now.get_year();
		var now_day = now.get_day_of_year();
		var now_week = now.get_week_of_year();

		var date_year = m_date.get_year();
		var date_day = m_date.get_day_of_year();
		var date_week = m_date.get_week_of_year();

		var formats = new Gee.ArrayList<string>();
		if(date_year == now_year)
		{
			if(date_day == now_day)
			{
				addTime = true;
			}
			else if(date_day == now_day -1)
			{
				formats.add(_("Yesterday").replace("%", "%%"));
				addTime = true;
			}
			else if(date_week == now_week)
			{
				formats.add("%A");
			}
			else
			{
				formats.add("%B %d");
			}
		}
		else
			formats.add("%Y-%m-%d");

		if(addTime)
		{
			if(clock_12_hour)
				formats.add("%l:%M %p");
			else
				formats.add("%H:%M");
		}

		string format = StringUtils.join(formats, ", ");
		return m_date.format(format);
	}

	public string getFeedID()
	{
		return m_feedID;
	}

	public ArticleStatus getUnread()
	{
		return m_unread;
	}

	public void setUnread(ArticleStatus unread)
	{
		m_unread = unread;
	}

	public ArticleStatus getMarked()
	{
		return m_marked;
	}

	public void setMarked(ArticleStatus marked)
	{
		m_marked = marked;
	}

	public unowned Gee.List<string> getTagIDs()
	{
		return m_tags;
	}

	public string getTagString()
	{
		return StringUtils.join(m_tags, ",");
	}

	public void setTags(Gee.List<string> tags)
	{
		m_tags = tags;
	}

	public void addTag(string tagID)
	{
		if(!m_tags.contains(tagID))
			m_tags.add(tagID);
	}

	public void removeTag(string tagID)
	{
		if(m_tags.contains(tagID))
			m_tags.remove(tagID);
	}

	public unowned Gee.List<string> getMedia()
	{
		return m_media;
	}

	public string getMediaString()
	{
		return StringUtils.join(m_media, ",");
	}

	public void setMedia(Gee.List<string> media)
	{
		m_media = media;
	}

	public void addMedia(string m)
	{
		if(!m_media.contains(m))
			m_media.add(m);
	}

	public bool haveMedia()
	{
		if(m_media.size > 0)
			return true;

		return false;
	}

	public string getHash()
	{
		return m_guidHash;
	}

	public int getLastModified()
	{
		return m_lastModified;
	}

	public int getPos()
	{
		return m_pos;
	}

	public void setPos(int pos)
	{
		m_pos = pos;
	}
}
