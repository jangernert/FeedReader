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

public class FeedReader.Utils : GLib.Object {

	public static string UTF8fix(string? old_string, bool removeHTML = false)
	{
		if(old_string == null)
		{
			Logger.warning("Utils.UTF8fix: string is NULL");
			return "NULL";
		}

		int rm_html = 0;
		if(removeHTML)
			rm_html = 1;

		string? output = old_string.replace("\n"," ").strip();
		output = libVilistextum.parse(old_string, rm_html);

		if(output != null)
		{
			output = output.replace("\n"," ").strip();
			if(output != "")
			{
				return output;
			}
		}
		return old_string;
	}

	public static string[] getDefaultExpandedCategories()
	{
		return {CategoryID.MASTER.to_string(), CategoryID.TAGS.to_string()};
	}

	public static GLib.DateTime convertStringToDate(string date)
	{
		return new GLib.DateTime(
			new TimeZone.local(),
			int.parse(date.substring(0, date.index_of_nth_char(4))),															// year
			int.parse(date.substring(date.index_of_nth_char(5), date.index_of_nth_char(7) - date.index_of_nth_char(5))),		// month
			int.parse(date.substring(date.index_of_nth_char(8), date.index_of_nth_char(10) - date.index_of_nth_char(8))),		// day
			int.parse(date.substring(date.index_of_nth_char(11), date.index_of_nth_char(13) - date.index_of_nth_char(11))),		// hour
			int.parse(date.substring(date.index_of_nth_char(14), date.index_of_nth_char(16) - date.index_of_nth_char(14))),		// min
			int.parse(date.substring(date.index_of_nth_char(17), date.index_of_nth_char(19) - date.index_of_nth_char(17)))		// sec
		);
	}

	public static bool springCleaningNecessary()
	{
		var lastClean = new DateTime.from_unix_local(Settings.state().get_int("last-spring-cleaning"));
		var now = new DateTime.now_local();

		var difference = now.difference(lastClean);
		bool doCleaning = false;

		Logger.debug("last clean: %s".printf(lastClean.format("%Y-%m-%d %H:%M:%S")));
		Logger.debug("now: %s".printf(now.format("%Y-%m-%d %H:%M:%S")));
		Logger.debug("difference: %f".printf(difference/GLib.TimeSpan.DAY));

		if((difference/GLib.TimeSpan.DAY) >= Settings.general().get_int("spring-clean-after"))
			doCleaning = true;

		return doCleaning;
	}

	// thanks to
	// http://kuikie.com/snippet/79-8/vala/strings/vala-generate-random-string/%7B$ROOT_URL%7D/terms/
	public static string string_random(int length = 8, string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890")
	{
		string random = "";

		for(int i=0;i<length;i++){
			int random_index = Random.int_range(0,charset.length);
			string ch = charset.get_char(charset.index_of_nth_char(random_index)).to_string();
			random += ch;
		}

		return random;
	}

	public static bool arrayContains(string[] array, string key)
	{
		foreach(string s in array)
		{
			if(s == key)
				return true;
		}

		return false;
	}

	public static void copyAutostart()
	{
		string filename = GLib.Environment.get_user_data_dir() + "/feedreader-autostart.desktop";

		if(Settings.tweaks().get_boolean("feedreader-autostart") && !FileUtils.test(filename, GLib.FileTest.EXISTS))
		{
			try
			{
				var origin = File.new_for_path(Constants.INSTALL_PREFIX + "/share/FeedReader/feedreader-autostart.desktop");
				var destination = File.new_for_path(filename);
	        	origin.copy(destination, FileCopyFlags.NONE);
			}
			catch(GLib.Error e)
			{
				Logger.error("Utils.copyAutostart: %s".printf(e.message));
			}
		}
	}

	public static string printTlsCertificateFlags(GLib.TlsCertificateFlags flag)
	{
		string errors = "";
		int flags = flag;

		if(flags - GLib.TlsCertificateFlags.GENERIC_ERROR >= 0)
		{
			errors += "GENERIC_ERROR ";
			flags -= GLib.TlsCertificateFlags.VALIDATE_ALL;
		}

		if(flags - GLib.TlsCertificateFlags.INSECURE >= 0)
		{
			errors += "INSECURE ";
			flags -= GLib.TlsCertificateFlags.INSECURE;
		}

		if(flags - GLib.TlsCertificateFlags.REVOKED >= 0)
		{
			errors += "REVOKED ";
			flags -= GLib.TlsCertificateFlags.REVOKED;
		}

		if(flags - GLib.TlsCertificateFlags.EXPIRED >= 0)
		{
			errors += "EXPIRED ";
			flags -= GLib.TlsCertificateFlags.EXPIRED;
		}

		if(flags - GLib.TlsCertificateFlags.NOT_ACTIVATED >= 0)
		{
			errors += "NOT_ACTIVATED ";
			flags -= GLib.TlsCertificateFlags.NOT_ACTIVATED;
		}

		if(flags - GLib.TlsCertificateFlags.BAD_IDENTITY >= 0)
		{
			errors += "BAD_IDENTITY ";
			flags -= GLib.TlsCertificateFlags.BAD_IDENTITY;
		}

		if(flags - GLib.TlsCertificateFlags.UNKNOWN_CA >= 0)
		{
			errors += "UNKNOWN_CA ";
			flags -= GLib.TlsCertificateFlags.UNKNOWN_CA;
		}

		return errors;
	}

	public static bool ping(string link)
	{
		Logger.debug("Ping: " + link);
		var uri = new Soup.URI(link);

		if(uri == null)
		{
			Logger.error("Ping failed: can't parse url! Seems to be not valid.");
			return false;
		}

		var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
		session.ssl_strict = false;

		var message = new Soup.Message.from_uri("HEAD", uri);
		var status = session.send_message(message);

		Logger.debug(@"Ping: status $status");

		if(status >= 200 && status <= 208)
		{
			Logger.debug("Ping successfull");
			return true;
		}

		Logger.error(@"Ping: failed %u - %s".printf(status, Soup.Status.get_phrase(status)));

		return false;
	}


	public static bool remove_directory(string path, uint level = 0)
	{
		++level;
		bool flag = false;

		try
		{
			var directory = GLib.File.new_for_path(path);

			var enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME, 0);

			GLib.FileInfo file_info;
			while((file_info = enumerator.next_file()) != null)
			{
				string file_name = file_info.get_name();

				if((file_info.get_file_type()) == GLib.FileType.DIRECTORY)
				{
					remove_directory(path + file_name + "/", level);
		    	}

				var file = directory.get_child(file_name);
				file.delete();
			}

			if(level == 1)
			{
				directory.delete();
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("Utils - remove_directory: " + e.message);
		}


		return flag;
	}


	public static string shortenURL(string url)
    {
        string longURL = url;
        if(longURL.has_prefix("https://"))
        {
            longURL = longURL.substring(8);
        }
        else if(longURL.has_prefix("http://"))
        {
            longURL = longURL.substring(7);
        }

        if(longURL.has_prefix("www."))
        {
            longURL = longURL.substring(4);
        }

        if(longURL.has_suffix("api/"))
        {
            longURL = longURL.substring(0, longURL.length - 4);
        }

        return longURL;
    }

	// thx to geary :)
	public static string prepareSearchQuery(string raw_query)
	{
        // Two goals here:
        //   1) append an * after every term so it becomes a prefix search
        //      (see <https://www.sqlite.org/fts3.html#section_3>), and
        //   2) strip out common words/operators that might get interpreted as
        //      search operators.
        // We ignore everything inside quotes to give the user a way to
        // override our algorithm here.  The idea is to offer one search query
        // syntax for Geary that we can use locally and via IMAP, etc.

        string quote_balanced = parseSearchTerm(raw_query).replace("'", " ");
        if(countChar(raw_query, '"') % 2 != 0)
		{
            // Remove the last quote if it's not balanced.  This has the
            // benefit of showing decent results as you type a quoted phrase.
            int last_quote = raw_query.last_index_of_char('"');
            assert(last_quote >= 0);
            quote_balanced = raw_query.splice(last_quote, last_quote + 1, " ");
        }

        string[] words = quote_balanced.split_set(" \t\r\n:()%*\\");
        bool in_quote = false;
        StringBuilder prepared_query = new StringBuilder();
        foreach(string s in words)
		{
            s = s.strip();

            int quotes = countChar(s, '"');
            if(!in_quote && quotes > 0)
			{
                in_quote = true;
                --quotes;
            }

            if(!in_quote)
			{
                string lower = s.down();
                if(lower == "" || lower == "and" || lower == "or" || lower == "not" || lower == "near" || lower.has_prefix("near/"))
                    continue;

                if(s.has_prefix("-"))
                    s = s.substring(1);

                if(s == "")
                    continue;

                s = "\"" + s + "*\"";
            }

            if(in_quote && quotes % 2 != 0)
                in_quote = false;

            prepared_query.append(s);
            prepared_query.append(" ");
        }

        assert(!in_quote);

        return prepared_query.str.strip();
    }

	public static int countChar(string s, unichar c)
	{
	    int count = 0;
	    for (int index = 0; (index = s.index_of_char(c, index)) >= 0; ++index, ++count)
	        ;
	    return count;
	}

	public static string parseSearchTerm(string searchTerm)
	{
		if(searchTerm.has_prefix("title: "))
		{
			return searchTerm.substring(7);
		}

		if(searchTerm.has_prefix("author: "))
		{
			return searchTerm.substring(8);
		}

		if(searchTerm.has_prefix("content: "))
		{
			return searchTerm.substring(9);
		}

		return searchTerm;
	}

	public static bool categoryIsPopulated(string catID, Gee.ArrayList<feed> feeds)
	{
		foreach(feed Feed in feeds)
		{
			var ids = Feed.getCatIDs();
			foreach(string id in ids)
			{
				if(id == catID)
				{
					return true;
				}
			}
		}

		return false;
	}

	public static uint categoryGetUnread(string catID, Gee.ArrayList<feed> feeds)
	{
		uint unread = 0;

		foreach(feed Feed in feeds)
		{
			var ids = Feed.getCatIDs();
			foreach(string id in ids)
			{
				if(id == catID)
				{
					unread += Feed.getUnread();
					break;
				}
			}
		}

		return unread;
	}

	public static void resetSettings(GLib.Settings settings)
	{
		var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}
	}

	public static string URLtoFeedName(string url)
	{
		var feedname = new GLib.StringBuilder(url);

		if(feedname.str.has_suffix("/"))
			feedname.erase(feedname.str.char_count()-1);

		if(feedname.str.has_prefix("https://"))
			feedname.erase(0, 8);

		if(feedname.str.has_prefix("http://"))
			feedname.erase(0, 7);

		if(feedname.str.has_prefix("www."))
			feedname.erase(0, 4);

		return feedname.str;
	}

	public static bool downloadIcon(string feed_id, string feed_url, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/")
	{
		var path = GLib.File.new_for_path(icon_path);
		try{path.make_directory_with_parents();}catch(GLib.Error e){}
		string local_filename = icon_path + feed_id.replace("/", "_").replace(".", "_") + ".ico";

		string url = feed_url;
		if(feed_url.has_prefix("http://"))
			url.replace("http://", "");
		else if(feed_url.has_prefix("https://"))
			url.replace("https://", "");

		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			Logger.debug("Utils: downloadIcon() url = \"%s\"".printf(url));

			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message ("GET", "http://f1.allesedv.com/32/%s".printf(url));

			if(Settings.tweaks().get_boolean("do-not-track"))
				message_dlIcon.request_headers.append("DNT", "1");

			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			var status = session.send_message(message_dlIcon);
			if (status == 200)
			{
				try
				{
					FileUtils.set_contents(local_filename, (string)message_dlIcon.response_body.flatten().data, (long)message_dlIcon.response_body.length);
				}
				catch(GLib.FileError e)
				{
					Logger.error("Error writing icon: %s".printf(e.message));
				}
				return true;
			}
			Logger.error("Error downloading icon for feed: %s".printf(feed_id));
			return false;
		}
		// file already exists
		return true;
	}
}
