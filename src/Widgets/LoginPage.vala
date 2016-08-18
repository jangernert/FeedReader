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

	private Gtk.ComboBox m_comboBox;
	private Gtk.Stack m_loginWidget;
	private Gtk.Box m_layout;
	private bool m_need_htaccess = false;
	private Peas.ExtensionSet m_extensions;
	private Peas.Engine m_engine;
	private WebLoginPage m_page;
	public signal void submit_data();
	public signal void loginError(LoginResponse errorCode);


	public LoginPage()
	{
		m_loginWidget = new Gtk.Stack();
		m_loginWidget.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_loginWidget.set_transition_duration(100);

		var liststore = new Gtk.ListStore(2, typeof(string), typeof(string));
		m_comboBox = new Gtk.ComboBox.with_model(liststore);
		m_comboBox.set_id_column(1);




		m_engine = Peas.Engine.get_default();
		m_engine.add_search_path(InstallPrefix + "/share/FeedReader/pluginsUI/", null);
		m_engine.enable_loader("python3");

		m_extensions = new Peas.ExtensionSet(m_engine, typeof(LoginInterface),
			"m_stack", m_loginWidget,
			"m_listStore", liststore,
			"m_logger", logger,
			"m_installPrefix", InstallPrefix);

		m_extensions.extension_added.connect((info, extension) => {
			var plugin = (extension as LoginInterface);
			plugin.init();
			plugin.login.connect(() => { writeLoginData(); });

			string plug = settings_general.get_string("plugin");
			m_comboBox.set_active_id(plug);
		});

		foreach(var plugin in m_engine.get_plugin_list())
		{
			m_engine.try_load_plugin(plugin);
		}


		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_layout.set_size_request(700, 410);
		m_layout.set_halign(Gtk.Align.CENTER);
		m_layout.set_valign(Gtk.Align.CENTER);
		m_layout.margin = 20;

		var welcomeText = new Gtk.Label(_("Where are your feeds?"));
		welcomeText.get_style_context().add_class("h1");
		welcomeText.set_justify(Gtk.Justification.CENTER);

		var welcomeText2 = new Gtk.Label(_("Please select the RSS service you are using and log in to get going."));
		welcomeText2.get_style_context().add_class("h2");
		welcomeText2.set_justify(Gtk.Justification.CENTER);
		welcomeText2.set_lines(3);


		m_layout.pack_start(welcomeText, false, true, 0);
		m_layout.pack_start(welcomeText2, false, true, 2);


		Gtk.CellRendererText renderer = new Gtk.CellRendererText();
		m_comboBox.pack_start(renderer, false);
		m_comboBox.add_attribute(renderer, "text", 0);
		m_comboBox.set_size_request(300, 0);
		m_comboBox.set_valign(Gtk.Align.CENTER);
		m_comboBox.set_halign(Gtk.Align.CENTER);

		var buttonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var loginButton = new Gtk.Button.with_label(_("Login"));
		loginButton.clicked.connect(writeLoginData);
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		buttonBox.pack_end(loginButton, false, false, 0);

		m_layout.pack_start(m_comboBox, false, false, 20);
		m_layout.pack_start(m_loginWidget, false, true, 10);
		m_layout.pack_start(buttonBox, false, true, 0);


		m_comboBox.changed.connect(() => {
			string? id = m_comboBox.get_active_id();

			if(id != null)
			{
				m_loginWidget.set_visible_child_name(id);
			}
		});

		var nothing_selected = new Gtk.Label(_("No service selected."));
		nothing_selected.get_style_context().add_class("h3");
		m_loginWidget.add_named(nothing_selected, "none");

		m_page = new WebLoginPage();
		this.add_named(m_page, "web");
		this.add_named(m_layout, "login");
		this.show_all();

		this.set_visible_child_name("login");
		m_loginWidget.set_visible_child_name("none");
	}


	public void showHtAccess()
	{
		getActivePlugin().showHtAccess();
		m_need_htaccess = true;
	}


	public void writeLoginData()
	{
		logger.print(LogMessage.DEBUG, "write login data");
		var extension = getActivePlugin();

		if(extension.needWebLogin())
		{
			m_page.loadPage(extension.buildLoginURL());
			m_page.getApiCode.connect(extension.extractCode);
			m_page.success.connect(login);
			this.set_visible_child_name("web");
		}
		else
		{
			extension.writeData();
			login();
		}
	}

	private void login()
	{
		LoginResponse status = feedDaemon_interface.login(getActivePluginName());
		logger.print(LogMessage.DEBUG, "LoginPage: status = " + status.to_string());
		if(status == LoginResponse.SUCCESS)
		{
			submit_data();
			return;
		}

		loginError(status);
	}

	private LoginInterface getActivePlugin()
	{
		string plugName = m_loginWidget.get_visible_child_name();
		var info = m_engine.get_plugin_info(plugName);
		return (m_extensions.get_extension(info) as LoginInterface);
	}

	private string getActivePluginName()
	{
		string plugName = m_loginWidget.get_visible_child_name();
		if(plugName.has_suffix("UI"))
			return plugName.substring(0, plugName.length-2);

		return "none";
	}
}
