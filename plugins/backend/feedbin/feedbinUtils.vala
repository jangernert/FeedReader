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

public class FeedReader.FeedbinUtils : GLib.Object {

	GLib.Settings m_settings;

	public FeedbinUtils()
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.feedbin");
	}

	public string getUser()
	{
		return Utils.gsettingReadString(m_settings, "username");
	}

	public void setUser(string user)
	{
		Utils.gsettingWriteString(m_settings, "username", user);
	}

	public string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										  "URL", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();

		string passwd = "";

		try{
			passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
		}
		catch(GLib.Error e){
			Logger.error(e.message);
		}

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

	public void setPassword(string passwd)
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										  "URL", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();
		try
		{
			Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "FeedReader: feedbin login", passwd, null);
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedbinUtils: setPassword: " + e.message);
		}
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
		deletePassword();
	}

	public bool deletePassword()
	{
		bool removed = false;
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										"URL", Secret.SchemaAttributeType.STRING,
										"Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();

		Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
			try
			{
				removed = Secret.password_clearv.end(async_res);
			}
			catch(GLib.Error e)
			{
				Logger.error("FeedbinUtils.deletePassword: %s".printf(e.message));
			}
		});
		return removed;
	}

	public string? catExists(Gee.List<category> categories, string name)
	{
		foreach(category cat in categories)
		{
			if(cat.getTitle() == name)
				return cat.getCatID();
		}

		return null;
	}

	public void addFeedToCat(Gee.List<Feed> feeds, string feedID, string catID)
	{
		foreach(Feed f in feeds)
		{
			if(f.getFeedID() == feedID)
			{
				f.setCats(ListUtils.single(catID));
			}
		}
	}

	public static string json_object_to_string(Json.Object obj)
	{
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(obj);

		var gen = new Json.Generator();
		gen.set_root(root);
		return gen.to_data(null);
	}
}
