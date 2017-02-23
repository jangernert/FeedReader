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
	private Peas.ExtensionSet m_plugins;
	private static Share? m_share = null;
	private Goa.Client? m_client = null;

	public static Share get_default()
	{
		if(m_share == null)
			m_share = new Share();

		return m_share;
	}

	private Share()
	{
		var engine = Peas.Engine.get_default();
		engine.add_search_path(Constants.INSTALL_PREFIX + "/" + Constants.INSTALL_LIBDIR + "/pluginsShare/", null);
		engine.enable_loader("python3");

		m_plugins = new Peas.ExtensionSet(engine, typeof(ShareAccountInterface));

		m_plugins.extension_added.connect((info, extension) => {
			var plugin = (extension as ShareAccountInterface);
			plugin.addAccount.connect(accountAdded);
			plugin.deleteAccount.connect(() => {
				refreshAccounts();
			});
		});

		//m_plugins.extension_removed.connect((info, extension) => {});

		checkSystemAccounts();

		foreach(var plugin in engine.get_plugin_list())
		{
			engine.try_load_plugin(plugin);
		}

		refreshAccounts();
	}

	public void refreshAccounts()
	{
		Logger.debug("Share: refreshAccounts");
		m_accounts = new Gee.ArrayList<ShareAccount>();
		m_plugins.foreach((@set, info, exten) => {
			var plugin = (exten as ShareAccountInterface);
			plugin.setupSystemAccounts(m_accounts);
			if(plugin.needSetup())
			{
				var plugID = plugin.pluginID();
				var accounts = Settings.share(plugID).get_strv("account-ids");
				foreach(string accountID in accounts)
				{
					m_accounts.add(
						new ShareAccount(
							accountID,
							plugin.pluginID(),
							plugin.getUsername(accountID),
							plugin.getIconName(),
							plugin.pluginName()
						)
					);
				}
			}
			else
			{
				m_accounts.add(
					new ShareAccount(
						plugin.pluginID(),
						plugin.pluginID(),
						plugin.pluginName(),
						plugin.getIconName(),
						plugin.pluginName()
					)
				);
			}
		});

		// load gresource-icons from the plugins
		Gtk.IconTheme.get_default().add_resource_path("/org/gnome/FeedReader/icons");
	}

	private ShareAccountInterface? getInterface(string type)
	{
		ShareAccountInterface? plug = null;

		m_plugins.foreach((@set, info, exten) => {
			var plugin = (exten as ShareAccountInterface);

			if(plugin.pluginID() == type)
			{
				plug = plugin;
			}
		});

		return plug;
	}

	public Gee.ArrayList<ShareAccount> getAccountTypes()
	{
		var accounts = new Gee.ArrayList<ShareAccount>();

		m_plugins.foreach((@set, info, exten) => {
			var plugin = (exten as ShareAccountInterface);

			if(plugin.needSetup() && !plugin.useSystemAccounts())
			{
				accounts.add(new ShareAccount("", plugin.pluginID(), "", plugin.getIconName(), plugin.pluginName()));
			}
		});

		return accounts;
	}


	public Gee.ArrayList<ShareAccount> getAccounts()
	{
		return m_accounts;
	}

	public string generateNewID()
	{
		string id = Utils.string_random(12);
		bool unique = true;

		m_plugins.foreach((@set, info, exten) => {
			var plugin = (exten as ShareAccountInterface);
			var plugID = plugin.pluginID();
			if(plugin.needSetup())
			{
				string[] ids = Settings.share(plugID).get_strv("account-ids");
				foreach(string i in ids)
				{
					if(i == id)
					{
						unique = false;
						return;
					}
				}
			}
		});

		if(!unique)
			return generateNewID();

		return id;
	}

	public void accountAdded(string id, string type, string username, string iconName, string accountName)
	{
		Logger.debug("Share: %s account added for user: %s".printf(type, username));
		m_accounts.add(new ShareAccount(id, type, username, iconName, accountName));
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
				return getInterface(account.getType()).addBookmark(accountID, url, account.isSystemAccount());
			}
		}

		return false;
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

	public ServiceSetup? newSystemAccount(string accountID)
	{
		foreach(var account in m_accounts)
		{
			if(account.getID() == accountID)
			{
				return getInterface(account.getType()).newSystemAccount(account.getID(), account.getUsername());
			}
		}

		return null;
	}

	public ShareForm? shareWidget(string type, string url)
	{
		ShareForm? form = null;

		m_plugins.foreach((@set, info, exten) => {
			var plugin = (exten as ShareAccountInterface);

			if(plugin.pluginID() == type)
			{
				form = plugin.shareWidget(url);
			}
		});

		return form;
	}

	private void checkSystemAccounts()
	{
		try
		{
			m_client = new Goa.Client.sync();
			if(m_client != null)
			{
				m_client.account_added.connect((obj) => {
					Logger.debug("share: account added");
					accountsChanged(obj);
				});
				m_client.account_changed.connect((obj) => {
					Logger.debug("share: account changed");
					accountsChanged(obj);
				});
				m_client.account_removed.connect((obj) => {
					Logger.debug("share: account removed");
					accountsChanged(obj);
				});
			}
			else
			{
				Logger.error("share: goa not available");
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("share.checkSystemAccounts: %s".printf(e.message));
		}
	}

	private void accountsChanged(Goa.Object object)
	{
		refreshAccounts();
		SettingsDialog.get_default().refreshAccounts();
		ColumnView.get_default().getHeader().refreshSahrePopover();
	}
}
