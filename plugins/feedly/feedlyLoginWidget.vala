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

FeedReader.Logger logger;

public class FeedReader.feedlyLoginWidget : Peas.ExtensionBase, LoginInterface {

	private FeedlyUtils m_utils;

	public Gtk.Stack m_stack { get; construct set; }
	public Gtk.ListStore m_listStore { get; construct set; }
	public Logger m_logger { get; construct set; }
	public string m_installPrefix { get; construct set; }

	public void init()
	{
		logger = m_logger;
		m_utils = new FeedlyUtils();
		var logo = new Gtk.Image.from_file(m_installPrefix + "/share/icons/hicolor/64x64/places/feed-service-feedly.svg");

		var text = new Gtk.Label(_("You will be redirected to the feedly website where you can use your Facebook-, Google-, Twitter-, Microsoft- or Evernote-Account to log in."));
		text.get_style_context().add_class("h3");
		text.set_justify(Gtk.Justification.CENTER);
		text.set_line_wrap_mode(Pango.WrapMode.WORD);
		text.set_line_wrap(true);
		text.set_lines(3);
		text.expand = false;
		text.set_width_chars(60);
		text.set_max_width_chars(60);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(text, true, true, 10);
		box.show_all();

		m_stack.add_named(box, "feedlyUI");

		Gtk.TreeIter iter;
		m_listStore.append(out iter);
		m_listStore.set(iter, 0, _("Feedly"), 1, "feedlyUI");
	}

	public bool needWebLogin()
	{
		return true;
	}

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{

	}

	public bool extractCode(string redirectURL)
	{
		if(redirectURL.has_prefix(FeedlySecret.apiRedirectUri))
		{
			logger.print(LogMessage.DEBUG, redirectURL);
			int start = redirectURL.index_of("=")+1;
			int end = redirectURL.index_of("&");
			string code = redirectURL.substring(start, end-start);
			m_utils.setApiCode(code);
			logger.print(LogMessage.DEBUG, "WebLoginPage: set feedly-api-code: " + code);
			GLib.Thread.usleep(500000);
			return true;
		}

		return false;
	}

	public string buildLoginURL()
	{
		return FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId
					+ "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.feedlyLoginWidget));
}
