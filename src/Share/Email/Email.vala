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


public class FeedReader.ShareMail : ShareAccountInterface, GLib.Object {

	public static const string ID = "mail";

	public bool addBookmark(string id, string url)
	{

		string body = _("Hey,\ncheck out this interesting article I just read:\n%s\n\n- send by FeedReader").printf(url);

		string mailto = "mailto:john.doe@domain.com?body=%s".printf(GLib.Uri.escape_string(body));

		logger.print(LogMessage.DEBUG, mailto);

		string[] spawn_args = {"xdg-open", mailto};
		try
		{
			GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
			return true;
		}
		catch(GLib.SpawnError e)
		{
			logger.print(LogMessage.ERROR, "spawning command line: " + e.message);
		}

		return false;
	}

	public bool logout(string id)
	{
		return false;
	}

	public string getIconName()
    {
        return "mail-send";
    }

	public string getUsername(string id)
	{
		return "Email";
	}

	public bool needSetup()
	{
		return false;
	}

	public string pluginID()
    {
        return ID;
    }

	public string pluginName()
	{
		return "Email";
	}

	public ServiceSetup? newSetup_withID(string id, string username)
    {
        return null;
    }

    public ServiceSetup? newSetup()
    {
        return null;
    }

}
