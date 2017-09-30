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
	private static FavIconCache? m_cache = null;

	public static FavIconCache get_default()
	{
		if(m_cache == null)
			m_cache = new FavIconCache();

		return m_cache;
	}

	private FavIconCache()
	{
		m_map = new Gee.HashMap<string, Gdk.Pixbuf>();
	}

	private async void load(string icon_name)
	{
		try
		{
			var fileName = icon_name + ".ico";
			var file = File.new_for_path(GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/" + fileName);
			try
			{
				var stream = yield file.read_async();
				var pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
				stream.close();
				if(pixbuf.get_height() <= 1 && pixbuf.get_width() <= 1)
				{
					Logger.warning(@"FavIconCache: $fileName is too small");
					return;
				}

				pixbuf = pixbuf.scale_simple(24, 24, Gdk.InterpType.BILINEAR);
				m_map.set(icon_name, pixbuf);
			}
			catch (FileError.NOENT e)
			{
				Logger.debug(@"FavIconCache: Icon $fileName does not exist");
				return;
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("FavIconCache.refresh: %s".printf(e.message));
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

	public async Gdk.Pixbuf? getIcon(string name, bool firstTry = true)
	{
		string fixedName = name.replace("/", "_").replace(".", "_");

		if(hasIcon(fixedName))
		{
			return m_map.get(fixedName).copy();
		}
		else if(firstTry)
		{
			yield load(name);
			return yield getIcon(name, false);
		}

		return null;
	}
}
