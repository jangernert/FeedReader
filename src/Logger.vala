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

public class FeedReader.Logger : GLib.Object {
	const string LOG_DOMAIN = "feedreader";

	private static bool m_log_debug_information = false;

	private static void log(LogLevelFlags level, string message)
	{
		GLib.log_structured(LOG_DOMAIN, level, "MESSAGE", "%s", message);
	}

	public static void error(string message)
	{
		log(GLib.LogLevelFlags.LEVEL_CRITICAL, message);
	}

	public static void warning(string message)
	{
		log(GLib.LogLevelFlags.LEVEL_WARNING, message);
	}

	public static void info(string message)
	{
		log(GLib.LogLevelFlags.LEVEL_INFO, message);
	}

	public static void debug(string message)
	{
		if(m_log_debug_information)
		{
			log(GLib.LogLevelFlags.LEVEL_DEBUG, message);
		}
	}

	public static void init(bool verbose)
	{
		m_log_debug_information = verbose;
		GLib.Log.set_writer_func((LogWriterFunc)GLib.Log.writer_standard_streams);
	}
}
