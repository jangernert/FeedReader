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

public class FeedReader.Settings : GLib.Object {

	private static GLib.Settings ? m_general = null;
	private static GLib.Settings ? m_tweaks = null;
	private static GLib.Settings ? m_state = null;
	private static GLib.Settings ? m_keys = null;
	private static Gee.HashMap<string, GLib.Settings>? m_share = null;

	public static GLib.Settings general()
	{
		if(m_general == null)
			m_general = new GLib.Settings("org.gnome.feedreader");

		return m_general;
	}

	public static GLib.Settings tweaks()
	{
		if(m_tweaks == null)
			m_tweaks = new GLib.Settings("org.gnome.feedreader.tweaks");

		return m_tweaks;
	}

	public static GLib.Settings state()
	{
		if(m_state == null)
			m_state = new GLib.Settings("org.gnome.feedreader.saved-state");

		return m_state;
	}

	public static GLib.Settings keybindings()
	{
		if(m_keys == null)
			m_keys = new GLib.Settings("org.gnome.feedreader.keybindings");

		return m_keys;
	}

	public static GLib.Settings ? share(string pluginName)
	{
		if(m_share == null)
			m_share = new Gee.HashMap<string, GLib.Settings>();

		if(m_share.has_key(pluginName))
			return m_share.get(pluginName);
		else
		{
			var settings = new GLib.Settings(@"org.gnome.feedreader.share.$pluginName");
			m_share.set(pluginName, settings);
			return settings;
		}
	}

	private Settings()
	{

	}
}
