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
	
	public static void send(uint new_articles, int new_and_unread)
	{
		string message = "";
		string summary = _("New articles");
		uint unread = DataBase.readOnly().get_unread_total();
		
		if(new_articles > 0 && new_and_unread > 0)
		{
			if(new_articles == 1)
			{
				message = _("There is 1 new article (%u unread)").printf(unread);
			}
			else
			{
				message = _("There are %u new articles (%u unread)").printf(new_articles, unread);
			}
			
			var notification = new GLib.Notification(summary);
			notification.set_body(message);
			notification.set_priority(GLib.NotificationPriority.NORMAL);
			notification.set_icon(new GLib.ThemedIcon("org.gnome.FeedReader"));
			
			GLib.Application.get_default().send_notification("feedreader_default", notification);
		}
	}
	
	private Notification()
	{
		
	}
}
