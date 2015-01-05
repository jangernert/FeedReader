/**
 * Representation model of one Entry from the "/v3/entries" 
 */
public abstract class Model.Entry : Object {

    public string id {get; set; }
    public string fingerprint {get; set; }
    public string originId {get; set; }
    public string author {get; set; }
    public string title {get; set; }
    public string summaryContent {get; set; }
    public string summaryDirection {get; set; }
    public DateTime published {get; set; }
    public string visualUrl {get; set; }
    public int visualWidth {get; set; }
    public int visualHeight {get; set; }
    public bool unread {get; set; }

    public Entry(string id, string fingerprint, string originId, string author,
                  string title, string summaryContent, string summaryDirection, DateTime published,
                  string visualUrl, int visualWidth, int visualHeight, bool unread
                  ) {

        this.id = id;
        this.fingerprint = fingerprint;
        this.originId = originId;
        this.author = author;
        this.title = title;
        this.summaryContent = summaryContent;
        this.summaryDirection = summaryDirection;
        this.published = published;
        this.visualUrl = visualUrl;
        this.visualWidth = visualWidth;
        this.visualHeight = visualHeight;
        this.unread = unread;
    }

    /** compare this article to another (by published date) */
    public int compare_to(Entry otherEntry) {
        return this.published.compare (otherEntry.published);
    }

    public abstract bool has_summary();

    public abstract bool has_visual();

    public abstract void mark_as_read ();
}