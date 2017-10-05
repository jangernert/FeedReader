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
	private WebLoginPage m_page;
	private Gtk.Box? m_activeWidget = null;
	public signal void submit_data();
	public signal void loginError(LoginResponse errorCode);


	public LoginPage()
	{
		FeedReaderBackend.get_default().tryLogin.connect(() => {
			writeLoginData();
		});

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

		FeedServer.get_default().getPlugins().foreach((extSet, info, ext) => {
			accountList.add(new LoginRow(ext as FeedServerInterface));
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
		FeedServer.get_default().setActivePlugin(extension.getID());

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
			});
		}
	}


	public void showHtAccess()
	{
		FeedServer.get_default().getActivePlugin().showHtAccess();
	}

	public void writeLoginData()
	{
		Logger.debug("write login data");
		var ext = FeedServer.get_default().getActivePlugin();
		if(ext != null)
		{
			ext.writeData();
			login(ext.getID());
		}
	}

	private void login(string id)
	{
		LoginResponse status = FeedReaderBackend.get_default().login(id);
		Logger.debug("LoginPage: status = " + status.to_string());
		if(status == LoginResponse.SUCCESS)
		{
			var ext = FeedServer.get_default().getActivePlugin();
			if(ext != null)
			{
				ext.postLoginAction.begin((ob, res) => {
					ext.postLoginAction.end(res);
					submit_data();
					FeedReaderBackend.get_default().startSync(true);
				});
			}


			return;
		}

		loginError(status);
	}
}
