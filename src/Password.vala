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

public class FeedReader.Password : GLib.Object {

	public delegate HashTable<string, string> GetAttributesFunc();

	private Secret.Collection m_secrets;
	private Secret.Schema m_schema;
	private GetAttributesFunc m_get_attributes;
	private string m_label;

	public Password(Secret.Collection secrets, Secret.Schema schema, string label, owned GetAttributesFunc get_attributes)
	{
		m_secrets = secrets;
		m_schema = schema;
		m_label = label;
		m_get_attributes = (owned)get_attributes;
	}

	public string get_password(Cancellable? cancellable = null)
	{
		var attributes = m_get_attributes();
		try
		{
			var secrets = m_secrets.search_sync(m_schema, attributes, Secret.SearchFlags.NONE, cancellable);

			if(cancellable != null && cancellable.is_cancelled())
				return "";

			if(secrets.length() != 0)
			{
				var item = secrets.data;
				item.load_secret_sync(cancellable);
				if(cancellable != null && cancellable.is_cancelled())
					return "";

				var secret = item.get_secret();
				if(secret == null)
				{
					Logger.error("Password.get_password: Got NULL secret");
					return "";
				}
				var password = secret.get_text();
				if(password == null)
				{
					Logger.error("Password.get_password: Got NULL password in non-NULL secret (secret isn't a text?)");
					return "";
				}
				return password;
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("Password.get_password: " + e.message);
		}
		return "";
	}

	public void set_password(string password, Cancellable? cancellable = null)
	{
		var attributes = m_get_attributes();
		try
		{
			var value = new Secret.Value(password, password.length, "text/plain");
			Secret.Item.create_sync(m_secrets, m_schema, attributes, m_label, value, Secret.ItemCreateFlags.REPLACE, cancellable);
		}
		catch(GLib.Error e)
		{
			Logger.error("Password.setPassword: " + e.message);
		}
	}

	public bool delete_password(Cancellable? cancellable = null)
	{
		var attributes = m_get_attributes();
		try
		{
			var secrets = m_secrets.search_sync(m_schema, attributes, Secret.SearchFlags.NONE, cancellable);

			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(secrets.length() != 0)
			{
				var item = secrets.data;
				item.delete_sync(cancellable);
				return true;
			}
			return false;
		}
		catch(GLib.Error e)
		{
			Logger.error("Password.delete_password: " + e.message);
			return false;
		}
	}
}
