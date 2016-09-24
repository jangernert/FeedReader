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
	public Logger m_logger { get; construct set; }
	public string m_installPrefix { get; construct set; }

	public void init()
	{
		logger = m_logger;
		m_utils = new FeedlyUtils();
	}

	public string getID()
	{
		return "feedly";
	}

	public string iconName()
	{
		return "feed-service-feedly";
	}

	public string serviceName()
	{
		return "feedly";
	}

	public bool needWebLogin()
	{
		return true;
	}

	public Gtk.Box? getWidget()
	{
		return null;
	}

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{
		return;
	}

	public void poastLoginAction()
	{
		return;
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
			logger.print(LogMessage.DEBUG, "feedlyLoginWidget: set feedly-api-code: " + code);
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
