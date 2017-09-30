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

public class FeedReader.StringUtils {
	public static Gee.List<string> split(string s, string sep, bool ignore_empty=false)
	{
		var items = s.split(sep);
		if (!ignore_empty)
			return new Gee.ArrayList<string>.wrap(items);

		var res = new Gee.ArrayList<string>();
		foreach(string item in items)
		{
			if(!ignore_empty || item.strip() != "")
				res.add(item);
		}
		return res;
	}

	public static string join(Gee.Collection<string> l, string sep)
	{
		return string.joinv(sep, l.to_array());
	}
}
