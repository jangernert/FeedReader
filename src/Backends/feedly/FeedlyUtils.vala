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

public class FeedReader.FeedlyUtils : Object {

	private GLib.Settings m_settings;

	public FeedlyUtils()
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.feedly");
	}

	public string getRefreshToken()
	{
		return m_settings.get_string("feedly-refresh-token");
	}

	public void setRefreshToken(string token)
	{
		m_settings.set_string("feedly-refresh-token", token);
	}

	public string getAccessToken()
	{
		return m_settings.get_string("feedly-access-token");
	}

	public void setAccessToken(string token)
	{
		m_settings.set_string("feedly-access-token", token);
	}

	public string getApiCode()
	{
		return m_settings.get_string("feedly-api-code");
	}

	public void setApiCode(string code)
	{
		m_settings.set_string("feedly-api-code", code);
	}

	public string getEmail()
	{
		return m_settings.get_string("email");
	}

	public void setEmail(string email)
	{
		m_settings.set_string("email", email);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
	}

}
