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

namespace FeedReader.FeedlySecret {
const string base_uri        = "http://cloud.feedly.com";
const string apiClientId     = "boutroue";
const string apiClientSecret = "FE012EGICU4ZOBDRBEOVAJA1JZYH";
const string apiRedirectUri  = "http://localhost";
const string apiAuthScope    = "https://cloud.feedly.com/subscriptions";
}

public class FeedReader.FeedlyUtils : Object {

private GLib.Settings m_settings;

public FeedlyUtils(GLib.SettingsBackend? settings_backend)
{
	if(settings_backend != null)
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.feedly", settings_backend);
	else
		m_settings = new GLib.Settings("org.gnome.feedreader.feedly");
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

public string getEmail()
{
	return Utils.gsettingReadString(m_settings, "email");
}

public void setEmail(string email)
{
	Utils.gsettingWriteString(m_settings, "email", email);
}

public int getExpiration()
{
	return m_settings.get_int("access-token-expires");
}

public void setExpiration(int seconds)
{
	m_settings.set_int("access-token-expires", seconds);
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
		Logger.warning("FeedlyUtils: access token expired");
		return false;
	}

	return true;
}
}
