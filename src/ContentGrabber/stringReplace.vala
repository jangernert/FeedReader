public class FeedReader.StringReplace : GLib.Object {
    private string m_toReplace;
    private string m_replaceWith;

    public StringReplace(string toReplace, string replaceWith)
    {
        m_toReplace = toReplace;
        m_replaceWith = replaceWith;
    }

    public string getToReplace()
    {
        return m_toReplace;
    }

    public string getReplaceWith()
    {
        return m_replaceWith;
    }
}
