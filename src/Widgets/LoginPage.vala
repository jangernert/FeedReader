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

public class FeedReader.LoginPage : Gtk.Stack {

	private Gtk.Box m_layout;
	private Peas.ExtensionSet m_extensions;
	private Peas.Engine m_engine;
	private WebLoginPage m_page;
	private string? m_activeExtension = null;
	private Gtk.Box? m_activeWidget = null;
	public signal void submit_data();
	public signal void loginError(LoginResponse errorCode);


	public LoginPage()
	{
		m_engine = Peas.Engine.get_default();
		m_engine.add_search_path(Constants.INSTALL_PREFIX + "/" + Constants.INSTALL_LIBDIR + "/pluginsUI/", null);
		m_engine.enable_loader("python3");

		m_extensions = new Peas.ExtensionSet(m_engine, typeof(LoginInterface));

		m_extensions.extension_added.connect((info, extension) => {
			var plugin = (extension as LoginInterface);
			plugin.init();
			plugin.login.connect(() => { writeLoginData(); });
		});

		foreach(var plugin in m_engine.get_plugin_list())
		{
			m_engine.try_load_plugin(plugin);
		}


		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_layout.set_size_request(700, 410);
		m_layout.set_halign(Gtk.Align.CENTER);
		m_layout.margin = 20;
		m_layout.margin_bottom = 50;
		m_layout.margin_top = 50;

		var welcomeText = new Gtk.Label(_("Where are your feeds?"));
		welcomeText.get_style_context().add_class("h1");
		welcomeText.set_justify(Gtk.Justification.CENTER);

		var welcomeText2 = new Gtk.Label(_("Please select the RSS service you are using and log in to get going."));
		welcomeText2.get_style_context().add_class("h2");
		welcomeText2.set_justify(Gtk.Justification.CENTER);
		welcomeText2.set_lines(3);


		var accountList = new Gtk.ListBox();
		accountList.set_selection_mode(Gtk.SelectionMode.NONE);
		accountList.row_activated.connect(serviceSelected);

		m_extensions.foreach((extSet, info, ext) => {
			accountList.add(new LoginRow(ext as LoginInterface));
		});

		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.set_size_request(450, 0);
		scroll.set_halign(Gtk.Align.CENTER);
		scroll.get_style_context().add_class(Gtk.STYLE_CLASS_FRAME);
		scroll.add(accountList);


		m_layout.pack_start(welcomeText, false, true, 0);
		m_layout.pack_start(welcomeText2, false, true, 2);
		m_layout.pack_start(scroll, true, true, 20);

		m_page = new WebLoginPage();
		this.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		this.add_named(m_page, "web");
		this.add_named(m_layout, "selectScreen");
		this.show_all();
		reset();
	}

	public void reset()
	{
		var visible = this.get_visible_child_name();
		this.set_visible_child_name("selectScreen");
		m_activeExtension = null;

		if(visible == "loginWidget"
		&& m_activeWidget != null)
		{
			this.remove(m_activeWidget);
			m_activeWidget = null;
		}
		else if(visible == "loginWidget")
		{
			m_page.reset();
		}
	}

	private void serviceSelected(Gtk.ListBoxRow row)
	{
		var serviceRow = (row as LoginRow);
		var extension = serviceRow.getExtension();
		Logger.debug("serviceSelected: %s".printf(serviceRow.getServiceName()));

		var window = MainWindow.get_default();
		window.getSimpleHeader().showBackButton(true);
		m_activeExtension = extension.getID();

		if(extension.needWebLogin())
		{
			m_page.reset();
			m_page.loadPage(extension.buildLoginURL());
			m_page.getApiCode.connect(extension.extractCode);
			m_page.success.connect(() => {
				login(extension.getID());
			});
			this.set_visible_child_name("web");

			window.getSimpleHeader().back.connect(() => {
				this.set_visible_child_full("selectScreen", Gtk.StackTransitionType.SLIDE_RIGHT);
				window.getSimpleHeader().showBackButton(false);
				m_page.reset();
				m_activeExtension = null;
			});
		}
		else
		{
			m_activeWidget = extension.getWidget();
			m_activeWidget.show_all();

			this.add_named(m_activeWidget, "loginWidget");
			this.set_visible_child_name("loginWidget");

			window.getSimpleHeader().back.connect(() => {
				this.set_visible_child_full("selectScreen", Gtk.StackTransitionType.SLIDE_RIGHT);
				window.getSimpleHeader().showBackButton(false);
				if(m_activeWidget != null)
				{
					this.remove(m_activeWidget);
					m_activeWidget = null;
				}
				m_activeExtension = null;
			});
		}
	}


	public void showHtAccess()
	{
		getActiveExtension().showHtAccess();
	}

	private LoginInterface? getActiveExtension()
	{
		LoginInterface? e = null;
		m_extensions.foreach((extSet, info, ext) => {
			var extension = (ext as LoginInterface);
			if(extension.getID() == m_activeExtension)
			{
				e = extension;
			}
		});
		return e;
	}

	public void writeLoginData()
	{
		Logger.debug("write login data");
		var ext = getActiveExtension();
		ext.writeData();
		login(ext.getID());
	}

	private void login(string id)
	{
		try
		{
			LoginResponse status = DBusConnection.get_default().login(id);
			Logger.debug("LoginPage: status = " + status.to_string());
			if(status == LoginResponse.SUCCESS)
			{
				var ext = getActiveExtension();
				ext.postLoginAction.begin((ob, res) => {
					ext.postLoginAction.end(res);
					submit_data();
					try
					{
						DBusConnection.get_default().startSync(true);
					}
					catch(GLib.Error e)
					{
						Logger.error("LoginPage: failed to start the initial sync - " + e.message);
					}

				});

				return;
			}

			loginError(status);
		}
		catch(GLib.Error e)
		{
			Logger.error("LoginPage.login: %s".printf(e.message));
		}
	}
}
