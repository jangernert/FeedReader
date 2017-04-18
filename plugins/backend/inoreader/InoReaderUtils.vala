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

namespace FeedReader.InoReaderSecret {
	 const string base_uri        = "https://www.inoreader.com/reader/api/0/";
	 const string apiClientId     = "1000001384";
	 const string apiClientSecret = "3AA9IyNTFL_Mgu77WPpWbawx9loERRdf";
	 const string apiRedirectUri  = "http://localhost";
	 const string csrf_protection = "123456";
}

public class FeedReader.InoReaderUtils : GLib.Object {

	private GLib.Settings m_settings;

	public InoReaderUtils()
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.inoreader");
	}

	public string getUser()
	{
		return m_settings.get_string("username");
	}

	public void setUser(string user)
	{
		m_settings.set_string("username", user);
	}

	public string getRefreshToken()
	{
		return m_settings.get_string("refresh-token");
	}

	public void setRefreshToken(string token)
	{
		m_settings.set_string("refresh-token", token);
	}

	public string getAccessToken()
	{
		return m_settings.get_string("access-token");
	}

	public void setAccessToken(string token)
	{
		m_settings.set_string("access-token", token);
	}

	public string getApiCode()
	{
		return m_settings.get_string("api-code");
	}

	public void setApiCode(string code)
	{
		m_settings.set_string("api-code", code);
	}

	public int getExpiration()
	{
		return m_settings.get_int("access-token-expires");
	}

	public void setExpiration(int seconds)
	{
		m_settings.set_int("access-token-expires", seconds);
	}

	public string getUserID()
	{
		return m_settings.get_string("user-id");
	}

	public void setUserID(string id)
	{
		m_settings.set_string("user-id", id);
	}

	public string getEmail()
	{
		return m_settings.get_string("user-email");
	}

	public void setEmail(string email)
	{
		m_settings.set_string("user-email", email);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
	}

	public bool accessTokenValid()
	{
		var now = new DateTime.now_local();

		if((int)now.to_unix() >  getExpiration())
		{
			Logger.warning("InoReaderUtils: access token expired");
			return false;
		}

		return true;
	}

	public bool tagIsCat(string tagID, Gee.List<feed> feeds)
	{
		foreach(feed Feed in feeds)
		{
			if(Feed.hasCat(tagID))
			{
				return true;
			}
		}
		return false;
	}
}
