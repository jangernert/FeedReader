public class FeedReader.Share : GLib.Object {

    private ReadabilityAPI m_readability;

    public Share()
    {
        m_readability = new ReadabilityAPI();
    }

    public void init()
    {
        // readability
        m_readability.getAccessToken();
    }

    public bool getRequestToken(OAuth type)
    {
        switch(type)
        {
            case OAuth.READABILITY:
                return m_readability.getRequestToken();

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

            default:
                return false;
        }
    }

    //share.addBookmark(OAuth.READABILITY, "http://www.hardwareluxx.de/index.php/news/software/betriebssysteme/35990-ios-9-update-soll-maengel-in-ios-84-wie-fehlende-privatfreigabe-beseitigen.html");

}
