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


public class FeedReader.Browser : ShareAccountInterface, Peas.ExtensionBase {

	public bool addBookmark(string id, string url, bool system)
	{
		Logger.debug("url: " + url);
		string[] spawn_args = {"xdg-open", url};
		try
		{
			GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
			return true;
		}
		catch(GLib.SpawnError e)
		{
			Logger.error("spawning command line: " + e.message);
		}

		return false;
	}

	public void setupSystemAccounts(Gee.ArrayList<ShareAccount> accounts)
	{

	}

	public bool logout(string id)
	{
		return false;
	}

	public string getIconName()
    {
		if(Gtk.IconTheme.get_default().lookup_icon("applications-internet", 0, Gtk.IconLookupFlags.FORCE_SVG) != null)
			return "applications-internet";

        return "feed-share-browser";
    }

	public string getUsername(string id)
	{
		return "Browser";
	}

	public bool needSetup()
	{
		return false;
	}

	public bool useSystemAccounts()
    {
        return false;
    }

	public string pluginID()
    {
        return "browser";
    }

	public string pluginName()
	{
		return _("Open in Browser");
	}

	public ServiceSetup? newSetup_withID(string id, string username)
    {
        return null;
    }

    public ServiceSetup? newSetup()
    {
        return null;
    }

	public ServiceSetup? newSystemAccount(string id, string username)
	{
		return null;
	}

	public ShareForm? shareWidget(string url)
	{
		return null;
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.Browser));
}
