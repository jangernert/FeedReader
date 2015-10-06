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

public class FeedReader.Share : GLib.Object {

	private GLib.List<ReadabilityAPI> m_readability;
	private GLib.List<PocketAPI> m_pocket;
	private GLib.List<InstaAPI> m_instapaper;

	public Share()
	{
		m_readability = new GLib.List<ReadabilityAPI>();
		var readabilityAccounts = settings_share.get_strv("readability");
		foreach(string id in readabilityAccounts)
		{
			m_readability.append(new ReadabilityAPI(id, "/org/gnome/feedreader/share/readability/%s/".printf(id)));
		}

		m_pocket = new GLib.List<PocketAPI>();
		var pocketAccounts = settings_share.get_strv("pocket");
		foreach(string id in pocketAccounts)
		{
			m_pocket.append(new PocketAPI(id, "/org/gnome/feedreader/share/pocket/%s/".printf(id)));
		}

		m_instapaper = new GLib.List<InstaAPI>();
		var instaAccounts = settings_share.get_strv("instapaper");
		foreach(string id in instaAccounts)
		{
			m_instapaper.append(new InstaAPI(id, "/org/gnome/feedreader/share/instapaper/%s/".printf(id)));
		}
	}


	public GLib.List<ShareAccount> getAccounts()
	{
		var list = new GLib.List<ShareAccount>();

		foreach(var account in m_readability)
		{
			list.append(new ShareAccount(account.getID(), OAuth.READABILITY, account.getUsername()));
		}

		foreach(var account in m_pocket)
		{
			list.append(new ShareAccount(account.getID(), OAuth.POCKET, account.getUsername()));
		}

		foreach(var account in m_instapaper)
		{
			list.append(new ShareAccount(account.getID(), OAuth.INSTAPAPER, account.getUsername()));
		}

		return list;
	}


	public string newAccount(OAuth type)
	{
		string id = Utils.string_random(12);

		switch(type)
        {
            case OAuth.READABILITY:
                m_readability.append(new ReadabilityAPI(id));
				break;
			case OAuth.POCKET:
				m_pocket.append(new PocketAPI(id));
				break;
			case OAuth.INSTAPAPER:
				m_instapaper.append(new InstaAPI(id));
				break;
        }

		return id;
	}


	public void deleteAccount(string accountID)
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				m_readability.remove(api);
				return;
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				m_pocket.remove(api);
				return;
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				m_instapaper.remove(api);
				return;
			}
		}
	}


	public void logout(string accountID)
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				api.logout();
				return;
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				api.logout();
				return;
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				api.logout();
				return;
			}
		}
	}

	public bool getRequestToken(string accountID)
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				return api.getRequestToken();
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				return api.getRequestToken();
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				return true;
			}
		}


		return false;
	}

	public bool getAccessToken(string accountID, string? verifier = "", string username = "", string password = "")
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID && verifier != null)
			{
				return api.getAccessToken(verifier);
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				return api.getAccessToken();
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				return api.getAccessToken(username, password);
			}
		}

		return false;
	}


	public void loginPage(string accountID)
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				Gtk.show_uri(Gdk.Screen.get_default(), api.getURL(), Gdk.CURRENT_TIME);
				return;
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				Gtk.show_uri(Gdk.Screen.get_default(), api.getURL(), Gdk.CURRENT_TIME);
				return;
			}
		}
	}


	public string getUsername(string accountID)
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				return api.getUsername();
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				return api.getUsername();
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				return api.getUsername();
			}
		}


		return "";
	}


	public bool addBookmark(string accountID, string url)
	{
		return false;
	}
}
