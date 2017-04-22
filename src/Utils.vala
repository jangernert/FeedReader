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

	private static Soup.Session? m_session;

	private static Soup.Session getSession()
	{
		if(m_session == null)
		{
			m_session = new Soup.Session();
			m_session.user_agent = Constants.USER_AGENT;
			m_session.ssl_strict = false;
			m_session.timeout = 1;
		}

		return m_session;
	}

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
		string desktop = "org.gnome.FeedReader-autostart.desktop";
		string filename = GLib.Environment.get_user_data_dir() + "/" + desktop;


		if(Settings.tweaks().get_boolean("feedreader-autostart") && !FileUtils.test(filename, GLib.FileTest.EXISTS))
		{
			try
			{
				var origin = File.new_for_path(Constants.INSTALL_PREFIX + "/share/FeedReader/" + desktop);
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

		var message = new Soup.Message.from_uri("HEAD", uri);
		var status = getSession().send_message(message);

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

	public static bool downloadFavIcon(string feed_id, string feed_url, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/")
	{

		var uri = new Soup.URI(feed_url);
		string hostname = uri.get_host();
		int first = hostname.index_of_char('.', 0);
		int second = hostname.index_of_char('.', first+1);
		if(second != -1 && first != second)
			hostname = hostname.substring(first+1);
		string siteURL = uri.get_scheme() + "://" + hostname;

		// download html and parse to find location of favicon
		var message_html = new Soup.Message("GET", siteURL);
		if(Settings.tweaks().get_boolean("do-not-track"))
			message_html.request_headers.append("DNT", "1");
		var status = getSession().send_message(message_html);
		if(status == 200)
		{
			var html = (string)message_html.response_body.flatten().data;

			var html_cntx = new Html.ParserCtxt();
	        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
	        Html.Doc* doc = html_cntx.read_doc(html, siteURL, null, Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
	        if(doc == null)
	        {
	            Logger.debug("Utils.downloadFavIcon: parsing html failed");
	    		return false;
	    	}

			// check for <link rel="icon">
			var xpath = grabberUtils.getURL(doc, "//link[@rel='icon']");

			if(xpath == null)
			// check for <link rel="shortcut icon">
				xpath = grabberUtils.getURL(doc, "//link[@rel='shortcut icon']");

			if(xpath == null)
				// check for <link rel="apple-touch-icon">
				xpath = grabberUtils.getURL(doc, "//link[@rel='apple-touch-icon']");

			if(xpath != null)
			{
				Logger.debug(@"Utils.downloadFavIcon: xpath success $xpath");
				xpath = grabberUtils.completeURL(xpath, siteURL);
				if(downloadIcon(feed_id, xpath, icon_path))
					return true;
			}
			else
			{
				Logger.debug("Utils.downloadFavIcon: xpath failed");
			}

			delete doc;
		}

		// try domainname/favicon.ico
		var icon_url = siteURL;
		if(!icon_url.has_suffix("/"))
			icon_url += "/";
		icon_url += "favicon.ico";
		return downloadIcon(feed_id, icon_url, icon_path);
	}

	public static bool downloadIcon(string feed_id, string? icon_url, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/")
	{
		if(icon_url == "" || icon_url == null || GLib.Uri.parse_scheme(icon_url) == null)
		{
			Logger.warning(@"Utils.downloadIcon: icon_url not valid $icon_url");
			return false;
		}

		var path = GLib.File.new_for_path(icon_path);
		try{path.make_directory_with_parents();}catch(GLib.Error e){}
		string filename_prefix = icon_path + feed_id.replace("/", "_").replace(".", "_");
		string local_filename = filename_prefix + ".ico";
		string metadata_filename = filename_prefix + ".txt";
		string cache_group = "cache";
		string etag_key = "etag";
		string last_modified_key = "last_modified";

		string? etag = null;
		// Normally, we would store a last modified time as a datetime type, but
		// servers aren't consistent about the format so we need to treat it as a
		// black box.
		string? last_modified = null;
		if(FileUtils.test(local_filename, GLib.FileTest.EXISTS)
		&& FileUtils.test(metadata_filename, GLib.FileTest.EXISTS))
		{
			var metadata = new KeyFile();
			try
			{
				try
				{
					metadata.load_from_file(metadata_filename, KeyFileFlags.NONE);
					try { etag = metadata.get_string(cache_group, etag_key); }
					catch (KeyFileError.KEY_NOT_FOUND e) {}
					catch (KeyFileError.GROUP_NOT_FOUND e) {}
					try { last_modified = metadata.get_string(cache_group, last_modified_key); }
					catch (KeyFileError.KEY_NOT_FOUND e) {}
					catch (KeyFileError.GROUP_NOT_FOUND e) {}
				}
				catch (KeyFileError.PARSE e)
				{
					// Try to load old-style etag metadata
					// TODO: At some point we should remove this backwards compatibility
					// Removing it will cause old clients to re-download all favicons,
					// so for efficiency it might be nice to leave this for one release
					Logger.warning(@"Utils.downloadIcon: Failed to load $metadata_filename as an INI. Treating it like an etag file instead.");
					etag = getFileContent(metadata_filename);
				}
				catch (KeyFileError e)
				{
					var message = e.message;
					Logger.warning(@"Utils.downloadIcon: Failed to read favicon metadata file $metadata_filename: $message");
				}
			}
			catch (FileError e)
			{
				var message = e.message;
				Logger.warning(@"Utils.downloadIcon: Failed to read favicon metadata file $metadata_filename: $message");
			}
		}

		Logger.debug(@"Utils.downloadIcon: url = $icon_url");
		var message = new Soup.Message("GET", icon_url);
		if(Settings.tweaks().get_boolean("do-not-track"))
			message.request_headers.append("DNT", "1");

		if(etag != null)
			message.request_headers.append("If-None-Match", etag);
		if(last_modified != null)
			message.request_headers.append("If-Modified-Since", last_modified);

		var status = getSession().send_message(message);
		if(status == 304)
		{
			var log = "Utils.downloadIcon: ";
			if(etag != null)
				log += @"etag ($etag) ";
			if(last_modified != null)
			{
				if(etag != null)
					log += "and ";
				log += @"last modified ($last_modified) ";
			}
			log += @"matched -> icon unchanged $feed_id";
			Logger.debug(log);
			return true;
		}
		else if(status == 200)
		{
			var data = message.response_body.flatten().data;
			if(FileUtils.test(local_filename, GLib.FileTest.EXISTS)
			&& (string)data == getFileContent(local_filename))
			{
				// file exists and is identical to remote file
				// we already downloaded it, but there is no need to write to the disc
				Logger.debug("Utils.downloadIcon: file identical -> icon unchanged");
			}
			else
			{
				try
				{
					FileUtils.set_data(local_filename, data);
				}
				catch(GLib.FileError e)
				{
					Logger.error("Error writing icon: %s".printf(e.message));
					return false;
				}
			}

			etag = message.response_headers.get_one("ETag");
			last_modified = message.response_headers.get_one("Last-Modified");
			// File downloaded successfully; time to save the caching metadata
			if(etag == null && last_modified == null)
			{
				if(FileUtils.unlink(metadata_filename) != 0)
					Logger.warning(@"Error deleting metadata file $metadata_filename");
			}
			else
			{
				var metadata = new KeyFile();
				if(etag != null)
					metadata.set_string(cache_group, etag_key, etag);
				if(last_modified != null)
					metadata.set_string(cache_group, last_modified_key, last_modified);
				try
				{
					metadata.save_to_file(metadata_filename);
				}
				catch (FileError e)
				{
					Logger.warning(@"Failed to save metadata file $metadata_filename: " + e.message);
				}
			}

			return true;
		}
		Logger.warning(@"Could not download icon for feed: $feed_id $icon_url, got response code $status");
		return false;
	}

	private static string? getFileContent(string filename)
	{
		try
		{
			string? contents = null;
			FileUtils.get_contents(filename, out contents);
			return contents;
		}
		catch(Error e)
		{
			Logger.warning(@"Utils.getFileContent: could not read file $filename");
		}

		return null;
	}
}
