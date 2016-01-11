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

	private Gee.ArrayList<ReadabilityAPI> m_readability;
	private Gee.ArrayList<PocketAPI> m_pocket;
	private Gee.ArrayList<InstaAPI> m_instapaper;

	public Share()
	{
		m_readability = new Gee.ArrayList<ReadabilityAPI>();
		var readabilityAccounts = settings_share.get_strv("readability");
		foreach(string id in readabilityAccounts)
		{
			m_readability.add(new ReadabilityAPI.open(id));
		}

		m_pocket = new Gee.ArrayList<PocketAPI>();
		var pocketAccounts = settings_share.get_strv("pocket");
		foreach(string id in pocketAccounts)
		{
			m_pocket.add(new PocketAPI.open(id));
		}

		m_instapaper = new Gee.ArrayList<InstaAPI>();
		var instaAccounts = settings_share.get_strv("instapaper");
		foreach(string id in instaAccounts)
		{
			m_instapaper.add(new InstaAPI.open(id));
		}
	}


	public Gee.ArrayList<ShareAccount> getAccounts()
	{
		var list = new Gee.ArrayList<ShareAccount>();

		foreach(var account in m_readability)
		{
			list.add(new ShareAccount(account.getID(), OAuth.READABILITY, account.getUsername()));
		}

		foreach(var account in m_pocket)
		{
			list.add(new ShareAccount(account.getID(), OAuth.POCKET, account.getUsername()));
		}

		foreach(var account in m_instapaper)
		{
			list.add(new ShareAccount(account.getID(), OAuth.INSTAPAPER, account.getUsername()));
		}

		return list;
	}


	public string newAccount(OAuth type)
	{
		string id = Utils.string_random(12);

		switch(type)
        {
            case OAuth.READABILITY:
                m_readability.add(new ReadabilityAPI(id));
				break;
			case OAuth.POCKET:
				m_pocket.add(new PocketAPI(id));
				break;
			case OAuth.INSTAPAPER:
				m_instapaper.add(new InstaAPI(id));
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
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				return api.addBookmark(url);
			}
		}

		foreach(var api in m_pocket)
		{
			if(api.getID() == accountID)
			{
				return api.addBookmark(url);
			}
		}

		foreach(var api in m_instapaper)
		{
			if(api.getID() == accountID)
			{
				return api.addBookmark(url);
			}
		}

		return false;
	}
}
