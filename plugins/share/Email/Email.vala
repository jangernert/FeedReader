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
		string mailto = @"mailto:$m_to?subject=$subject&body=$body";
		Logger.debug(mailto);

		try
		{
			Gtk.show_uri_on_window(MainWindow.get_default(), mailto, Gdk.CURRENT_TIME);
			return true;
		}
		catch(GLib.Error e)
		{
			Logger.error("share via mail failed: %s".printf(e.message));
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
		if(Gtk.IconTheme.get_default().lookup_icon("mail-send", 0, Gtk.IconLookupFlags.FORCE_SVG) != null)
			return "mail-send";

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

	public bool singleInstance()
	{
		return true;
	}

	public bool useSystemAccounts()
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
