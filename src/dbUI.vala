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

public class FeedReader.dbUI : dbBase {

	private static dbUI? m_dataBase = null;

	public static new dbUI get_default()
	{
		if(m_dataBase == null)
		{
			m_dataBase = new dbUI();
			if(m_dataBase.uninitialized())
				m_dataBase.init();
		}


		return m_dataBase;
	}

	public dbUI(string dbFile = "feedreader-%01i.db".printf(Constants.DB_SCHEMA_VERSION))
	{
		base(dbFile);
	}

	protected override bool showCategory(string catID, Gee.ArrayList<Feed> feeds)
	{
		try
		{
			if(DBusConnection.get_default().hideCategoryWhenEmpty(catID)
			&& !Utils.categoryIsPopulated(catID, feeds))
			{
				return false;
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("dbUI.showCategory: %s".printf(e.message));
		}
		return true;
	}

	protected override string getUncategorizedQuery()
	{
		try
		{
			string catID = DBusConnection.get_default().uncategorizedID();
			return "category_id = \"%s\"".printf(catID);
		}
		catch(GLib.Error e)
		{
			Logger.error("dbUI.showCategory: %s".printf(e.message));
		}

		return "";
	}

}
