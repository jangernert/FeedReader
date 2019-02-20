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

public class FeedReader.StringPair : GLib.Object {
	private string m_string1;
	private string m_string2;
	
	public StringPair(string string1, string string2)
	{
		m_string1 = string1;
		m_string2 = string2;
	}
	
	public string getString1()
	{
		return m_string1;
	}
	
	public string getString2()
	{
		return m_string2;
	}
}
