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
			m_accounts.add(new ShareAccount(id, OAuth.READABILITY, username, iconName, "Readability"));
		}

		foreach(string id in pocketAccounts)
		{
			string username = PocketAPI.getUsername(id);
			string iconName = PocketAPI.getIconName();
			m_accounts.add(new ShareAccount(id, OAuth.POCKET, username, iconName, "Pocket"));
		}

		foreach(string id in instaAccounts)
		{
			string username = InstaAPI.getUsername(id);
			string iconName = InstaAPI.getIconName();
			m_accounts.add(new ShareAccount(id, OAuth.INSTAPAPER, username, iconName, "Instapaper"));
		}

		m_accounts.add(new ShareAccount("1234", OAuth.MAIL, ShareMail.getUsername(""), ShareMail.getIconName(), "Email"));
	}

	public Gee.ArrayList<ShareAccount> getAccountTypes()
	{
		var accounts = new Gee.ArrayList<ShareAccount>();
		accounts.add(new ShareAccount("", OAuth.READABILITY, "", ReadabilityAPI.getIconName(), "Readability"));
		accounts.add(new ShareAccount("", OAuth.POCKET, "", PocketAPI.getIconName(), "Pocket"));
		accounts.add(new ShareAccount("", OAuth.INSTAPAPER, "", InstaAPI.getIconName(), "Instapaper"));
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
					case OAuth.POCKET:
						PocketAPI.logout(accountID);
						return;

					case OAuth.READABILITY:
						ReadabilityAPI.logout(accountID);
						return;

					case OAuth.INSTAPAPER:
						InstaAPI.logout(accountID);
						return;
				}
			}
		}
	}

	public string getRequestToken(OAuth type)
	{
		switch(type)
		{
			case OAuth.POCKET:
				return PocketAPI.getRequestToken();

			case OAuth.READABILITY:
				return ReadabilityAPI.getRequestToken();

			case OAuth.INSTAPAPER:
			default:
				return "";
		}
	}

	public bool getAccessToken(OAuth type, out string id, string? verifier = "", string username = "", string password = "")
	{
		// TODO: check if string is already in use
		id = Utils.string_random(12);

		switch(type)
		{
			case OAuth.POCKET:
				if(PocketAPI.getAccessToken(verifier, id))
				{
					string usr = PocketAPI.getUsername(id);
					string icon = PocketAPI.getIconName();
					m_accounts.add(new ShareAccount(id, OAuth.POCKET, usr, icon, "Pocket"));
					return true;
				}
				break;

			case OAuth.READABILITY:
				if(ReadabilityAPI.getAccessToken(verifier, id))
				{
					string usr = ReadabilityAPI.getUsername(id);
					string icon = ReadabilityAPI.getIconName();
					m_accounts.add(new ShareAccount(id, OAuth.READABILITY, usr, icon, "Readability"));
					return true;
				}
				break;

			case OAuth.INSTAPAPER:
				if(InstaAPI.getAccessToken(id, username, password))
				{
					string usr = InstaAPI.getUsername(id);
					string icon = InstaAPI.getIconName();
					m_accounts.add(new ShareAccount(id, OAuth.INSTAPAPER, usr, icon, "Instapaper"));
					return true;
				}
				break;
		}

		return false;
	}


	public void loginPage(OAuth type, string token)
	{
		string url = "";

		switch(type)
		{
			case OAuth.POCKET:
				url = PocketAPI.getURL(token);
				break;

			case OAuth.READABILITY:
				url = ReadabilityAPI.getURL(token);
				break;

			case OAuth.INSTAPAPER:
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
					case OAuth.POCKET:
						return PocketAPI.getUsername(accountID);

					case OAuth.READABILITY:
						return ReadabilityAPI.getUsername(accountID);

					case OAuth.INSTAPAPER:
						return InstaAPI.getUsername(accountID);

					case OAuth.MAIL:
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
					case OAuth.POCKET:
						return PocketAPI.addBookmark(accountID, url);

					case OAuth.READABILITY:
						return ReadabilityAPI.addBookmark(accountID, url);

					case OAuth.INSTAPAPER:
						return InstaAPI.addBookmark(accountID, url);

					case OAuth.MAIL:
						return ShareMail.addBookmark(accountID, url);
				}
			}
		}

		return false;
	}
}
