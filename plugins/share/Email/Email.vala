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


public class FeedReader.ShareMail : ShareAccountInterface, Peas.ExtensionBase {

	private string m_body;
	private string m_to;

	public bool addBookmark(string id, string url, bool system)
	{
		string subject = GLib.Uri.escape_string("Amazing article");
		string body = GLib.Uri.escape_string(m_body.replace("$URL", url));
		string mailto = "mailto:%s?subject=%s&body=%s".printf(m_to, subject, body);
		Logger.debug(mailto);

		string[] spawn_args = {"xdg-open", mailto};
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

	public bool logout(string id)
	{
		return false;
	}

	public string getIconName()
    {
        return "feed-share-mail";
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
        return "mail";
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

	public ServiceSetup? newSystemAccount(string id, string username)
	{
		return null;
	}

	public ShareForm? shareWidget(string url)
	{
		var widget = new EmailForm(url);
		widget.share.connect(() => {
			m_to = widget.getTo();
			m_body = widget.getBody();
		});
		return widget;
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.ShareMail));
}
