public class FeedReader.Logger : GLib.Object {

	private int m_LogLevel;

	public Logger()
	{
		var logLevel = settings_general.get_enum("log-level");
		m_LogLevel = LogLevel.DEBUG;
		
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


	public void print(LogMessage level, string message)
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
				break;

			case LogMessage.WARNING:
				set_color(ConsoleColor.YELLOW);
				stdout.printf("[WARNING] ");
				break;

			case LogMessage.INFO:
				set_color(ConsoleColor.GREEN);
				stdout.printf("[ INFO  ] ");
				break;

			case LogMessage.DEBUG:
				set_color(ConsoleColor.BLUE);
				stdout.printf("[ DEBUG ] ");
				break;
		}

		reset_color();
		stdout.printf("%s\n", message);
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

}
