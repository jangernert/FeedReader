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

public InoReaderUtils(GLib.SettingsBackend? settings_backend)
{
	if(settings_backend != null)
	{
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.inoreader", settings_backend);
	}
	else
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.inoreader");
	}
}

public string getUser()
{
	return Utils.gsettingReadString(m_settings, "username");
}

public void setUser(string user)
{
	Utils.gsettingWriteString(m_settings, "username", user);
}

public string getRefreshToken()
{
	return Utils.gsettingReadString(m_settings, "refresh-token");
}

public void setRefreshToken(string token)
{
	Utils.gsettingWriteString(m_settings, "refresh-token", token);
}

public string getAccessToken()
{
	return Utils.gsettingReadString(m_settings, "access-token");
}

public void setAccessToken(string token)
{
	Utils.gsettingWriteString(m_settings, "access-token", token);
}

public string getApiCode()
{
	return Utils.gsettingReadString(m_settings, "api-code");
}

public void setApiCode(string code)
{
	Utils.gsettingWriteString(m_settings, "api-code", code);
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
	return Utils.gsettingReadString(m_settings, "user-id");
}

public void setUserID(string id)
{
	Utils.gsettingWriteString(m_settings, "user-id", id);
}

public string getEmail()
{
	return Utils.gsettingReadString(m_settings, "user-email");
}

public void setEmail(string email)
{
	Utils.gsettingWriteString(m_settings, "user-email", email);
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

public bool tagIsCat(string tagID, Gee.List<Feed> feeds)
{
	foreach(Feed feed in feeds)
	{
		if(feed.hasCat(tagID))
		{
			return true;
		}
	}
	return false;
}
}
