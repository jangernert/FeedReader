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

public class FeedReader.InterfaceState : GLib.Object {

    private int m_WindowHeight = 900;
    private int m_WindowWidth = 1600;
    private int m_FeedsAndArticleWidth = 600;
    private int m_FeedListWidth = 200;
    private int m_ArticleListRowCount = 15;
    private int m_ArticleListNewRowCount = 0;
    private int m_ArticleViewScrollPos = 0;
    private bool m_WindowMaximized = false;
    private double m_ArticleListScrollPos = 0.0;
    private double m_FeedListScrollPos = 0.0;
    private string m_SearchTerm = "";
    private string m_FeedListSelectedRow = "feed -4";
    private string m_ArticleListSelectedRow = "0";
    private string[] m_ExpandedCategories = {};
    private ArticleListState m_ArticleListState = ArticleListState.ALL;

    public InterfaceState()
    {

    }

    public void write()
    {
        settings_state.set_int      ("window-width",                m_WindowWidth);
        settings_state.set_int      ("window-height",               m_WindowHeight);
        settings_state.set_boolean  ("window-maximized",            m_WindowMaximized);
        settings_state.set_strv     ("expanded-categories",         m_ExpandedCategories);
        settings_state.set_double   ("feed-row-scrollpos",          m_FeedListScrollPos);
        settings_state.set_string   ("feedlist-selected-row",       m_FeedListSelectedRow);
        settings_state.set_int      ("feed-row-width",              m_FeedListWidth);
        settings_state.set_int      ("feeds-and-articles-width",    m_FeedsAndArticleWidth);
        settings_state.set_int      ("articlelist-row-amount",      m_ArticleListRowCount);
        settings_state.set_double   ("articlelist-scrollpos",       m_ArticleListScrollPos);
        settings_state.set_string   ("articlelist-selected-row",    m_ArticleListSelectedRow);
        settings_state.set_enum     ("show-articles",               m_ArticleListState);
        settings_state.set_string   ("search-term",                 m_SearchTerm);
        settings_state.set_int      ("articleview-scrollpos",       m_ArticleViewScrollPos);
        settings_state.set_int      ("articlelist-new-rows",        m_ArticleListNewRowCount);
    }

    public void setWindowSize(int height, int width)
    {
        m_WindowHeight = height;
        m_WindowWidth = width;
    }

    public int getWindowHeight()
    {
        return m_WindowHeight;
    }

    public int getWindowWidth()
    {
        return m_WindowWidth;
    }

    public void setFeedsAndArticleWidth(int size)
    {
        m_FeedsAndArticleWidth = size;
    }

    public int getFeedsAndArticleWidth()
    {
        return m_FeedsAndArticleWidth;
    }

    public void setFeedListWidth(int size)
    {
        m_FeedListWidth = size;
    }

    public int getFeedListWidth()
    {
        return m_FeedListWidth;
    }

    public void setFeedListScrollPos(double pos)
    {
        m_FeedListScrollPos = pos;
    }

    public double getFeedListScrollPos()
    {
        return m_FeedListScrollPos;
    }

    public void setArticleViewScrollPos(int pos)
    {
        m_ArticleViewScrollPos = pos;
    }

    public int getArticleViewScrollPos()
    {
        return m_ArticleViewScrollPos;
    }

    public void setArticleListScrollPos(double pos)
    {
        m_ArticleListScrollPos = pos;
    }

    public double getArticleListScrollPos()
    {
        return m_ArticleListScrollPos;
    }

    public void setArticleListRowCount(int count)
    {
        m_ArticleListRowCount = count;
    }

    public int getArticleListRowCount()
    {
        return m_ArticleListRowCount;
    }

    public void setArticleListSelectedRow(string articleID)
    {
        m_ArticleListSelectedRow = articleID;
    }

    public string getArticleListSelectedRow()
    {
        return m_ArticleListSelectedRow;
    }

    public void setArticleListNewRowCount(int count)
    {
        m_ArticleListNewRowCount = count;
    }

    public int getArticleListNewRowCount()
    {
        return m_ArticleListNewRowCount;
    }

    public void setWindowMaximized(bool max)
    {
        m_WindowMaximized = max;
    }

    public bool getWindowMaximized()
    {
        return m_WindowMaximized;
    }

    public void setSearchTerm(string search)
    {
        m_SearchTerm = search;
    }

    public string getSearchTerm()
    {
        return m_SearchTerm;
    }

    public void setFeedListSelectedRow(string code)
    {
        m_FeedListSelectedRow = code;
    }

    public string getFeedListSelectedRow()
    {
        return m_FeedListSelectedRow;
    }

    public void setExpandedCategories(string[] array)
    {
        m_ExpandedCategories = array;
    }

    public string[] getExpandedCategories()
    {
        return m_ExpandedCategories;
    }

    public void setArticleListState(ArticleListState state)
    {
        m_ArticleListState = state;
    }

    public ArticleListState getArticleListState()
    {
        return m_ArticleListState;
    }

}
