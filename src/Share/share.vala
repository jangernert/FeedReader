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
	private Gee.ArrayList<ShareAccountInterface> m_interfaces;

	public Share()
	{
		m_interfaces = new Gee.ArrayList<ShareAccountInterface>();
		m_interfaces.add(new ReadabilityAPI());
		m_interfaces.add(new PocketAPI());
		m_interfaces.add(new InstaAPI());
		m_interfaces.add(new ShareMail());

		m_accounts = new Gee.ArrayList<ShareAccount>();

		foreach(var interfce in m_interfaces)
		{
			if(interfce.needSetup())
			{
				var accounts = settings_share.get_strv(interfce.pluginID());
				foreach(string id in accounts)
				{
					m_accounts.add(
						new ShareAccount(
							id,
							interfce.pluginID(),
							interfce.getUsername(id),
							interfce.getIconName(),
							interfce.pluginName()
						)
					);
				}
			}
			else
			{
				m_accounts.add(
					new ShareAccount(
						"",
						interfce.pluginID(),
						interfce.pluginName(),
						interfce.getIconName(),
						interfce.pluginName()
					)
				);
			}

		}
	}

	private ShareAccountInterface? getInterface(string type)
	{
		foreach(var interfce in m_interfaces)
		{
			if(interfce.pluginID() == type)
			{
				return interfce;
			}
		}

		return null;
	}

	public Gee.ArrayList<ShareAccount> getAccountTypes()
	{
		var accounts = new Gee.ArrayList<ShareAccount>();

		foreach(var interfce in m_interfaces)
		{
			if(interfce.needSetup())
			{
				accounts.add(new ShareAccount("", interfce.pluginID(), "", interfce.getIconName(), interfce.pluginName()));
			}
		}

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
				getInterface(account.getType()).logout(accountID);
			}
		}
	}

	public string getRequestToken(string type)
	{
		return getInterface(type).getRequestToken();
	}

	public bool getAccessToken(string type, out string id, string? verifier = "", string username = "", string password = "")
	{
		// TODO: check if string is already in use
		id = Utils.string_random(12);

		var api = getInterface(type);

		if(api.getAccessToken(id, verifier, username, password))
		{
			string usr = api.getUsername(id);
			string icon = api.getIconName();
			string name = api.pluginName();
			m_accounts.add(new ShareAccount(id, type, usr, icon, name));
			return true;
		}

		return false;
	}


	public void loginPage(string type, string token)
	{
		string url = getInterface(type).getURL(token);
		Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
	}


	public string getUsername(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				return getInterface(account.getType()).getUsername(accountID);
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
				return getInterface(account.getType()).addBookmark(accountID, url);
			}
		}

		return false;
	}

	public string parseArg(string arg, out string verifier)
	{

		foreach(var interfce in m_interfaces)
		{
			if(interfce.isArg(arg))
			{
				verifier = interfce.parseArgs(arg);
				return interfce.pluginID();
			}
		}

		return "none";
	}

	public bool needSetup(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				return getInterface(account.getType()).needSetup();
			}
		}

		return false;
	}

	public ServiceSetup? newSetup_withID(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				return getInterface(account.getType()).newSetup_withID(account.getID(), account.getUsername());
			}
		}

		return null;
	}

	public ServiceSetup? newSetup(string type)
	{
		return getInterface(type).newSetup();
	}
}
