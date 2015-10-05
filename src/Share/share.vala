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
	//private GLib.List<PocketAPI> m_pocket;
	//private GLib.List<InstaAPI> m_instapaper;

	public Share()
	{
		m_readability = new GLib.List<ReadabilityAPI>();
		var readabilityAccounts = settings_share.get_strv("readability");
		foreach(string id in readabilityAccounts)
		{
			m_readability.append(new ReadabilityAPI(id, "/org/gnome/feedreader/share/readability/%s/".printf(id)));
		}
	}


	public GLib.List<ShareAccount> getAccounts()
	{
		var list = new GLib.List<ShareAccount>();

		foreach(var account in m_readability)
		{
			list.append(new ShareAccount(account.getID(), OAuth.READABILITY, account.getUsername()));
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

		return false;
	}

	public bool getAccessToken(string accountID, string verifier = "", string username = "", string password = "")
	{
		foreach(var api in m_readability)
		{
			if(api.getID() == accountID)
			{
				return api.getAccessToken(verifier);
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


		// FIXME: instapaper & pocket
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


		return "";
	}


	public bool addBookmark(string accountID, string url)
	{
		return false;
	}
}
