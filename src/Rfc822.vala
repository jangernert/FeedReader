namespace FeedReader.Rfc822 {

	/**
	* Parse a date string in RFC 822 format
	* Note that we don't use Time.strptime because it uses the current locale
	* to parse month names, but RFC 822 specifically requires months to be
	* written in English.
	* See: https://www.w3.org/Protocols/rfc822/#z28
	* And: https://groups.yahoo.com/neo/groups/rss-public/conversations/topics/536
	* */
	public static DateTime? parseDate(string? str)
	{
		if (str == null)
		{
			return null;
		}

		Regex re;
		try {
			re = new Regex("""
				# We don't care about the day of the week
				\s*(?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s*)?
				(?<day>\d{1,2})\s+
				(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+
				# The standard specifies 2-digit years but 4 digit years are
				# recommended now.
				# This pattern will also accept 3-digit years, so we'll have to
				# check for that separately
				(?<year>\d{2,4})\s+
				(?<hour>\d{2})
				:(?<minute>\d{2})
				(?::(?<second>\d{2}))?\s+
				(?<zone>UT|GMT|EST|EDT|MST|MDT|PST|PDT|[A-Z]|(?:[+-]\d{4}))
				""",
				RegexCompileFlags.CASELESS | RegexCompileFlags.EXTENDED,
			RegexMatchFlags.ANCHORED);
		} catch (RegexError e) {
			stderr.printf("RFC822 regex failed to parse: %s\n", e.message);
			assert(false);
			return null;
		}

		MatchInfo info;
		if (!re.match(str, 0, out info))
		{
			return null;
		}

		var dayStr = info.fetch_named("day");
		var day = int.parse(dayStr);

		var monthStr = info.fetch_named("month").ascii_down();
		int month;
		switch(monthStr) {
			case "jan":
			month = 1;
			break;
			case "feb":
			month = 2;
			break;
			case "mar":
			month = 3;
			break;
			case "apr":
			month = 4;
			break;
			case "may":
			month = 5;
			break;
			case "jun":
			month = 6;
			break;
			case "jul":
			month = 7;
			break;
			case "aug":
			month = 8;
			break;
			case "sep":
			month = 9;
			break;
			case "oct":
			month = 10;
			break;
			case "nov":
			month = 11;
			break;
			case "dec":
			month = 12;
			break;
			default:
			// The regex should make this impossible
			assert(false);
			return null;
		}

		var yearStr = info.fetch_named("year");
		var year = int.parse(yearStr);
		// Two-digit years from 00 to 49 should be interpreted as 2000 to 2049
		if (year >= 0 && year <= 49)
		{
			year += 2000;
		}
		// Two-digit years from 50 to 99 should be interpreted as 1950 to 1999
		else if (year >= 50 && year < 100)
		{
			year += 1900;
		}
		var hourStr = info.fetch_named("hour");
		var hour = int.parse(hourStr);
		var minuteStr = info.fetch_named("minute");
		var minute = int.parse(minuteStr);
		var secondStr = info.fetch_named("second");
		var second = secondStr == null || secondStr == "" ? 0 : int.parse(secondStr);

		var zoneStr = info.fetch_named("zone");
		TimeZone zone;
		switch(zoneStr.ascii_up()) {
			// Note sure if new TimeZone(zoneStr) would always work for these,
			// so specifically handle the cases the spec requires
			case "EDT":
			zone = new TimeZone("-04");
			break;
			case "CDT":
			case "EST":
			zone = new TimeZone("-05");
			break;
			case "CST":
			case "MDT":
			zone = new TimeZone("-06");
			break;
			case "MST":
			case "PDT":
			zone = new TimeZone("-07");
			break;
			case "PST":
			zone = new TimeZone("-08");
			break;

			case "GMT":
			case "UT":
			case "Z":
			zone = new TimeZone.utc();
			break;
			default:
			zone = new TimeZone(zoneStr);
			break;
		}

		return new DateTime(zone, year, month, day, hour, minute, second);
	}
}
