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

	private int m_LogLevel;
	private GLib.FileOutputStream m_stream;

	private static Logger? m_logger = null;
	private static string? m_fileName = null;

	public static void init(string filename)
	{
		m_fileName = filename;
	}

	private static Logger get_default()
	{
		string name = "uninitialized";

		if(m_fileName != null)
			name = m_fileName;

		if(m_logger == null)
			m_logger = new Logger(name);

		return m_logger;
	}

	public static void error(string message)
	{
		get_default().print(LogMessage.ERROR, message);
	}

	public static void warning(string message)
	{
		get_default().print(LogMessage.WARNING, message);
	}

	public static void info(string message)
	{
		get_default().print(LogMessage.INFO, message);
	}

	public static void debug(string message)
	{
		get_default().print(LogMessage.DEBUG, message);
	}


	private Logger(string filename)
	{
		var logLevel = Settings.general().get_enum("log-level");
		m_LogLevel = LogLevel.DEBUG;

		string path = "%s/.local/share/feedreader/%s.log".printf(GLib.Environment.get_home_dir(), filename);

		if(FileUtils.test(path, GLib.FileTest.EXISTS))
			GLib.FileUtils.remove(path);

		var file = GLib.File.new_for_path(path);
		try
		{
			m_stream = file.create(FileCreateFlags.NONE);
		}
		catch(GLib.Error e)
		{
			stderr.printf("error creating log-file: %s\n", e.message);
		}


		switch(logLevel)
		{
			case LogLevel.OFF:
				print(LogMessage.INFO, "Logs are deactivated!");
				break;

			case LogLevel.ERROR:
				print(LogMessage.INFO, "Only critical Errors are logged!");
				break;

			case LogLevel.MORE:
				print(LogMessage.INFO, "Errors and some general information is logged!");
				break;

			case LogLevel.DEBUG:
				print(LogMessage.INFO, "Everything is logged. Used to debug!");
				break;
		}

		m_LogLevel = logLevel;
	}

	private void print(LogMessage level, string message)
	{
		switch(m_LogLevel)
		{
			case LogLevel.OFF:
				return;

			case LogLevel.ERROR:
				if(level != LogMessage.ERROR)
					return;
				break;

			case LogLevel.MORE:
				if(level > LogMessage.INFO)
					return;
				break;

			case LogLevel.DEBUG:
				break;
		}

		switch(level)
		{
			case LogMessage.ERROR:
				set_color(ConsoleColor.RED);
				stdout.printf("[ ERROR ] ");
				write("[ ERROR ] ");
				break;

			case LogMessage.WARNING:
				set_color(ConsoleColor.YELLOW);
				stdout.printf("[WARNING] ");
				write("[WARNING] ");
				break;

			case LogMessage.INFO:
				set_color(ConsoleColor.GREEN);
				stdout.printf("[ INFO  ] ");
				write("[ INFO  ] ");
				break;

			case LogMessage.DEBUG:
				set_color(ConsoleColor.BLUE);
				stdout.printf("[ DEBUG ] ");
				write("[ DEBUG ] ");
				break;
		}

		reset_color();
		stdout.printf("%s\n", message);
		write("%s\n".printf(message));
	}

	private void reset_color()
	{
		stdout.printf("\x001b[0m");
	}

	private void set_color(ConsoleColor color)
	{
		var color_code = color + 30 + 60;
		stdout.printf("\x001b[%dm", color_code);
	}

	private void write(string text)
	{
		try
		{
			m_stream.write(text.data);
		}
		catch(GLib.Error e)
		{
			stderr.printf("[ ERROR ] error writing log to file: %s\n", e.message);
			stderr.printf("[ ERROR ] %s\n", text);
			reset_color();
		}
	}

}
