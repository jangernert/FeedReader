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

public class FeedReader.InoReaderLoginWidget : Peas.ExtensionBase, LoginInterface {

	private InoReaderUtils m_utils;

	public Logger m_logger { get; construct set; }
	public string m_installPrefix { get; construct set; }

	public void init()
	{
		logger = m_logger;
		m_utils = new InoReaderUtils();
	}

	public string getID()
	{
		return "inoreader";
	}

	public string iconName()
	{
		return "feed-service-inoreader";
	}

	public string serviceName()
	{
		return "InoReader";
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
		if(redirectURL.has_prefix(InoReaderSecret.apiRedirectUri))
		{
			logger.print(LogMessage.DEBUG, redirectURL);
			int csrf_start = redirectURL.index_of("state=")+6;
			string csrf_code = redirectURL.substring(csrf_start);
			logger.print(LogMessage.DEBUG, "InoReaderLoginWidget: csrf_code: " + csrf_code);

			if(csrf_code == InoReaderSecret.csrf_protection)
			{
				int start = redirectURL.index_of("code=")+5;
				int end = redirectURL.index_of("&", start);
				string code = redirectURL.substring(start, end-start);
				m_utils.setApiCode(code);
				logger.print(LogMessage.DEBUG, "InoReaderLoginWidget: set inoreader-api-code: " + code);
				GLib.Thread.usleep(500000);
				return true;
			}

			logger.print(LogMessage.ERROR, "InoReaderLoginWidget: csrf_code mismatch");
		}
		else
		{
			logger.print(LogMessage.WARNING, "InoReaderLoginWidget: wrong redirect_uri: " + redirectURL);
		}

		return false;
	}

	public string buildLoginURL()
	{
		return "https://www.inoreader.com/oauth2/auth"
			+ "?client_id=" + InoReaderSecret.apiClientId
			+ "&redirect_uri=" + InoReaderSecret.apiRedirectUri
			+ "&response_type=code"
			+ "&scope=read+write"
			+ "&state=" + InoReaderSecret.csrf_protection;
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
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.InoReaderLoginWidget));
}
