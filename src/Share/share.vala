public class FeedReader.Share : GLib.Object {

    private ReadabilityAPI m_readability;
    private PocketAPI m_pocket;
    private InstaAPI m_instapaper;

    public Share()
    {
        m_readability = new ReadabilityAPI();
        m_pocket = new PocketAPI();
        m_instapaper = new InstaAPI();
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
                return m_instapaper.login(username, password);

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
