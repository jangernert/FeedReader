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
