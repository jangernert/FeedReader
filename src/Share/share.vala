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

	private Gee.ArrayList<ShareAccount> m_accounts;

	public Share()
	{
		m_accounts = new Gee.ArrayList<ShareAccount>();
		var readabilityAccounts = settings_share.get_strv("readability");
		var pocketAccounts = settings_share.get_strv("pocket");
		var instaAccounts = settings_share.get_strv("instapaper");

		foreach(string id in readabilityAccounts)
		{
			string username = ReadabilityAPI.getUsername(id);
			string iconName = ReadabilityAPI.getIconName();
			m_accounts.add(new ShareAccount(id, ReadabilityAPI.ID, username, iconName, "Readability"));
		}

		foreach(string id in pocketAccounts)
		{
			string username = PocketAPI.getUsername(id);
			string iconName = PocketAPI.getIconName();
			m_accounts.add(new ShareAccount(id, PocketAPI.ID, username, iconName, "Pocket"));
		}

		foreach(string id in instaAccounts)
		{
			string username = InstaAPI.getUsername(id);
			string iconName = InstaAPI.getIconName();
			m_accounts.add(new ShareAccount(id, InstaAPI.ID, username, iconName, "Instapaper"));
		}

		m_accounts.add(new ShareAccount("1234", ShareMail.ID, ShareMail.getUsername(""), ShareMail.getIconName(), "Email"));
	}

	public Gee.ArrayList<ShareAccount> getAccountTypes()
	{
		var accounts = new Gee.ArrayList<ShareAccount>();
		accounts.add(new ShareAccount("", ReadabilityAPI.ID, "", ReadabilityAPI.getIconName(), "Readability"));
		accounts.add(new ShareAccount("", PocketAPI.ID, "", PocketAPI.getIconName(), "Pocket"));
		accounts.add(new ShareAccount("", InstaAPI.ID, "", InstaAPI.getIconName(), "Instapaper"));
		return accounts;
	}


	public Gee.ArrayList<ShareAccount> getAccounts()
	{
		return m_accounts;
	}


	public void deleteAccount(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				m_accounts.remove(account);

				switch(account.getType())
				{
					case PocketAPI.ID:
						PocketAPI.logout(accountID);
						return;

					case ReadabilityAPI.ID:
						ReadabilityAPI.logout(accountID);
						return;

					case InstaAPI.ID:
						InstaAPI.logout(accountID);
						return;
				}
			}
		}
	}

	public string getRequestToken(string type)
	{
		switch(type)
		{
			case PocketAPI.ID:
				return PocketAPI.getRequestToken();

			case ReadabilityAPI.ID:
				return ReadabilityAPI.getRequestToken();

			case InstaAPI.ID:
			default:
				return "";
		}
	}

	public bool getAccessToken(string type, out string id, string? verifier = "", string username = "", string password = "")
	{
		// TODO: check if string is already in use
		id = Utils.string_random(12);

		switch(type)
		{
			case PocketAPI.ID:
				if(PocketAPI.getAccessToken(verifier, id))
				{
					string usr = PocketAPI.getUsername(id);
					string icon = PocketAPI.getIconName();
					m_accounts.add(new ShareAccount(id, PocketAPI.ID, usr, icon, "Pocket"));
					return true;
				}
				break;

			case ReadabilityAPI.ID:
				if(ReadabilityAPI.getAccessToken(verifier, id))
				{
					string usr = ReadabilityAPI.getUsername(id);
					string icon = ReadabilityAPI.getIconName();
					m_accounts.add(new ShareAccount(id, ReadabilityAPI.ID, usr, icon, "Readability"));
					return true;
				}
				break;

			case InstaAPI.ID:
				if(InstaAPI.getAccessToken(id, username, password))
				{
					string usr = InstaAPI.getUsername(id);
					string icon = InstaAPI.getIconName();
					m_accounts.add(new ShareAccount(id, InstaAPI.ID, usr, icon, "Instapaper"));
					return true;
				}
				break;
		}

		return false;
	}


	public void loginPage(string type, string token)
	{
		string url = "";

		switch(type)
		{
			case PocketAPI.ID:
				url = PocketAPI.getURL(token);
				break;

			case ReadabilityAPI.ID:
				url = ReadabilityAPI.getURL(token);
				break;

			case InstaAPI.ID:
			default:
				return;
		}

		Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
	}


	public string getUsername(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				switch(account.getType())
				{
					case PocketAPI.ID:
						return PocketAPI.getUsername(accountID);

					case ReadabilityAPI.ID:
						return ReadabilityAPI.getUsername(accountID);

					case InstaAPI.ID:
						return InstaAPI.getUsername(accountID);

					case ShareMail.ID:
						return ShareMail.getUsername(accountID);
				}
			}
		}


		return "";
	}


	public bool addBookmark(string accountID, string url)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				switch(account.getType())
				{
					case PocketAPI.ID:
						return PocketAPI.addBookmark(accountID, url);

					case ReadabilityAPI.ID:
						return ReadabilityAPI.addBookmark(accountID, url);

					case InstaAPI.ID:
						return InstaAPI.addBookmark(accountID, url);

					case ShareMail.ID:
						return ShareMail.addBookmark(accountID, url);
				}
			}
		}

		return false;
	}
}
