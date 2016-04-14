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

public class FeedReader.OPMLparser : GLib.Object {

	private string m_opmlString;

	public OPMLparser(string opml)
	{
		m_opmlString = opml;

		var cntx = new Xml.ParserCtxt();
		cntx.use_options(Xml.ParserOption.NOERROR + Xml.ParserOption.NOWARNING);
		Xml.Doc* doc = cntx.read_doc(m_rawHtml, "");
		if (doc == null)
		{
			return false;
		}
	}
}
