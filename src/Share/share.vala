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

public class FeedReader.Share : GLib.Object {

    private ReadabilityAPI m_readability;
    private PocketAPI m_pocket;
    private InstaAPI m_instapaper;

    public Share()
    {
        m_readability = new ReadabilityAPI();
        m_pocket = new PocketAPI();
        m_instapaper = new InstaAPI();

        //checkAccessTokens.begin((obj, res) => {
        //    checkAccessTokens.end(res);
        //});
    }

    public async void checkAccessTokens()
	{
		SourceFunc callback = checkAccessTokens.callback;

		ThreadFunc<void*> run = () => {
            m_instapaper.checkLogin();
            m_instapaper.getUserID();
            m_readability.getUsername();

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("checkAccessTokens", run);
		yield;
	}

    public bool getRequestToken(OAuth type)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.getRequestToken();

            case OAuth.POCKET:
                return m_pocket.getRequestToken();

            case OAuth.INSTAPAPER:
                return true;

            default:
                return false;
        }
    }

    public bool getAccessToken(OAuth type, string username = "", string password = "")
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.getAccessToken();

            case OAuth.POCKET:
                return m_pocket.getAccessToken();

            case OAuth.INSTAPAPER:
                return m_instapaper.getAccessToken(username, password);

            default:
                return false;
        }
    }

    public bool addBookmark(OAuth type, string url)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.addBookmark(url);

            case OAuth.POCKET:
                return m_pocket.addBookmark(url);

            case OAuth.INSTAPAPER:
                return m_instapaper.addBookmark(url);

            default:
                return false;
        }
    }


    public bool logout(OAuth type)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.logout();

            case OAuth.POCKET:
                return m_pocket.logout();

            case OAuth.INSTAPAPER:
                return m_instapaper.logout();

            default:
                return false;
        }
    }
}
