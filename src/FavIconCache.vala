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

public class FeedReader.FavIconCache : GLib.Object {

	private Gee.HashMap<string, Gdk.Pixbuf> m_map;
	private static FavIconCache ? m_cache = null;

	public static FavIconCache get_default()
	{
		if(m_cache == null)
			m_cache = new FavIconCache();

		return m_cache;
	}

	private FavIconCache()
	{
		m_map = new Gee.HashMap<string, Gdk.Pixbuf>();
		refresh(true);
	}

	private void refresh(bool logs = false)
	{
		try
		{
			var iconDirPath = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/";
			var iconDirectory = GLib.File.new_for_path(iconDirPath);
			if(!iconDirectory.query_exists())
			{
				try
				{
					iconDirectory.make_directory_with_parents();
				}
				catch(GLib.Error e)
				{
					if(logs)
						Logger.error("FavIconCache: Can't create directory: %s".printf(e.message));
				}
			}
			var enumerator = iconDirectory.enumerate_children(GLib.FileAttribute.STANDARD_NAME, 0);
			GLib.FileInfo ? fileInfo = null;
			GLib.File ? file = null;

			while(true)
			{
				if(enumerator.iterate(out fileInfo, out file))
				{
					if(fileInfo == null)
						break;

					string fileName = fileInfo.get_name();

					if(!fileName.has_suffix(".ico"))
						continue;

					if(!hasIcon(fileName))
					{
						try
						{
							var pixbuf = new Gdk.Pixbuf.from_file(iconDirPath + fileName);

							if(pixbuf.get_height() <= 1 && pixbuf.get_width() <= 1)
							{
								if(logs)
									Logger.warning(@"$fileName too small");
								continue;
							}

							pixbuf = new Gdk.Pixbuf.from_file_at_scale(iconDirPath + fileName, 24, 24, true);
							fileName = fileName.substring(0, fileName.length - ".ico".length);
							m_map.set(fileName, pixbuf);
						}
						catch(GLib.Error e)
						{
							if(logs)
								Logger.warning("Error loading favicon " + fileInfo.get_name());
						}
					}
				}
				else
				{
					if(logs)
						Logger.warning("Error loading favicon " + fileInfo.get_name());
				}
			}
		}
		catch(GLib.Error e)
		{
			if(logs)
				Logger.error("FavIconCache: %s".printf(e.message));
		}
	}

	private bool hasIcon(string iconName)
	{
		if(m_map == null)
		{
			m_map = new Gee.HashMap<string, Gdk.Pixbuf>();
			return false;
		}

		return m_map.has_key(iconName);
	}

	public Gdk.Pixbuf ? getIcon(string name, bool firstTry = true)
	{
		string fixedName = name.replace("/", "_").replace(".", "_");

		if(hasIcon(fixedName))
		{
			return m_map.get(fixedName).copy();
		}
		else if(firstTry)
		{
			Logger.warning(@"FavIconCache: does not contain icon $fixedName");
			refresh();
			return getIcon(name, false);
		}

		return null;
	}
}
