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
		var fileName = GLib.Base64.encode(icon_name.data) + ".ico";
		//var fileName = icon_name + ".ico";
		try
		{
			var file = File.new_for_path(GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/" + fileName);
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
		catch (IOError.NOT_FOUND e)
		{
			Logger.debug(@"FavIconCache: Icon $fileName does not exist");
		}
		catch(Gdk.PixbufError.UNKNOWN_TYPE e)
		{
			Logger.warning(@"FavIconCache.load: Icon $fileName is an unknown type");
		}
		catch(Error e)
		{
			Logger.error(@"FavIconCache.load: $fileName: %s".printf(e.message));
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
		if(hasIcon(name))
		{
			return m_map.get(name).copy();
		}
		else if(firstTry)
		{
			yield load(name);
			return yield getIcon(name, false);
		}

		return null;
	}
}
