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

public class FeedReader.Notification : GLib.Object {

	private static bool m_notifyActionSupport = false;
	private static Notify.Notification m_notification;

	public static void init()
	{
		Notify.init(AboutInfo.programmName);
		GLib.List<string> notify_server_caps = Notify.get_server_caps();
		foreach(string str in notify_server_caps)
		{
			if(str == "actions")
			{
				m_notifyActionSupport = true;
				Logger.info("daemon: Notification actions supported");
				break;
			}
		}
	}

	public static bool supportAction()
	{
		return m_notifyActionSupport;
	}

	public static void send(uint newArticles)
	{
		try
		{
			string message = "";
			string summary = _("New Articles");
			uint unread = dbDaemon.get_default().get_unread_total();

			if(!Notify.is_initted())
			{
				Logger.error("notification: libnotifiy not initialized");
				return;
			}

			if(newArticles > 0)
			{
				if(unread == 1)
					message = _("There is 1 new article (%u unread)").printf(unread);
				else
					message = _("There are %u new articles (%u unread)").printf(newArticles, unread);

				if(m_notification == null)
				{
					m_notification = new Notify.Notification(summary, message, AboutInfo.iconName);
					m_notification.set_urgency(Notify.Urgency.NORMAL);
					m_notification.set_app_name(AboutInfo.programmName);
					m_notification.set_hint("desktop-entry", new Variant ("(s)", "org.gnome.FeedReader"));

					if(Notification.supportAction())
					{
						m_notification.add_action ("default", "Show FeedReader", (notification, action) => {
							Logger.debug("notification: default action");

							try
							{
							    m_notification.close();
							    string[] spawn_args = {"feedreader"};
							    GLib.Process.spawn_async("/", spawn_args, null, GLib.SpawnFlags.SEARCH_PATH, null, null);
							}
							catch(Error e)
							{
							    Logger.error("Notification: close - " + e.message);
							}
						});
					}
				}
				else
				{
					m_notification.update(summary, message, AboutInfo.iconName);
				}

				m_notification.show();
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("Notification: send - " + e.message);
		}
	}

	private Notification()
	{

	}
}
