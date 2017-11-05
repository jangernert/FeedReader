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

class FeedReader.FeedbinUtils : GLib.Object {
	static Secret.Schema m_pwSchema =
		new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
						   "URL", Secret.SchemaAttributeType.STRING,
						   "Username", Secret.SchemaAttributeType.STRING);

	GLib.Settings m_settings;
	Password m_password;

	public FeedbinUtils(GLib.SettingsBackend settings_backend, Secret.Collection secrets)
	{
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.feedbin", settings_backend);
		m_password = new Password(secrets, m_pwSchema, "FeedReader: feedbin login", getPasswordAttributes);
	}

	public string getUser()
	{
		return Utils.gsettingReadString(m_settings, "username");
	}

	public void setUser(string user)
	{
		Utils.gsettingWriteString(m_settings, "username", user);
	}

	private HashTable<string, string> getPasswordAttributes()
	{
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();
		return attributes;
	}

	public string getPassword(Cancellable? cancellable = null)
	{
		return m_password.get_password(cancellable);
	}

	public void setPassword(string password, Cancellable? cancellable = null)
	{
		m_password.set_password(password, cancellable);
	}

	public void resetAccount(Cancellable? cancellable = null)
	{
		Utils.resetSettings(m_settings);
		deletePassword(cancellable);
	}

	public bool deletePassword(Cancellable? cancellable = null)
	{
		return m_password.delete_password(cancellable);
	}
}
