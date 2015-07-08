public class FeedReader.Share : GLib.Object {

    private ReadabilityAPI m_readability;
    private PocketAPI m_pocket;

    public Share()
    {
        m_readability = new ReadabilityAPI();
        m_pocket = new PocketAPI();
    }

    public bool getRequestToken(OAuth type)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.getRequestToken();

            case OAuth.POCKET:
                return m_pocket.getRequestToken();

            default:
                return false;
        }
    }

    public bool getAccessToken(OAuth type)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.getAccessToken();

            case OAuth.POCKET:
                return m_pocket.getAccessToken();

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

            default:
                return false;
        }
    }
}
