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

    public dbUI (string dbFile = "feedreader-04.db") {
        base(dbFile);
    }

    protected override bool showCategory(string catID, Gee.ArrayList<feed> feeds)
	{
        if(feedDaemon_interface.hideCagetoryWhenEmtpy(catID)
        && !Utils.categoryIsPopulated(catID, feeds))
        {
            return false;
        }
        return true;
	}

    protected override string getUncategorizedQuery()
	{
		string catID = feedDaemon_interface.uncategorizedID();
		return "category_id = \"%s\"".printf(catID);
	}

}
