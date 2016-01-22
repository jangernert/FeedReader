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

public class FeedReader.inoreader_utils : GLib.Object {

	public static string getApi()
	{
		return settings_inoreader.get_string ("inoreader-api-key");
	}
	public static string getApiToken()
	{
		return settings_inoreader.get_string ("inoreader-api-token");
	}
	public static string getUser()
	{
		return settings_inoreader.get_string ("inoreader-api-username");
	}

	public static string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "Apikey", Secret.SchemaAttributeType.STRING,
							                      "Apisecret", Secret.SchemaAttributeType.STRING,
							                      "Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["Apikey"] = settings_inoreader.get_string ("inoreader-api-key");
		attributes["Apisecret"] = settings_inoreader.get_string ("inoreader-api-token");
		attributes["Username"] = settings_inoreader.get_string ("inoreader-api-username");

		string passwd = "";
		try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}
		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}
}
