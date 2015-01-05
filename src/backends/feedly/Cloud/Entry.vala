/**
 * Representation model of one Entry from the "/v3/entries" 
 */
public class Entry : Model.Entry {

    public Entry(string id, string fingerprint, string originId, string author,
                  string title, string summaryContent, string summaryDirection, DateTime published,
                  string visualUrl, int visualWidth, int visualHeight, bool unread
                  ) {
        base (id, fingerprint, originId, author, title, summaryContent, summaryDirection, published,
                  visualUrl, visualWidth, visualHeight, unread);
    }

    /**
     * Check if this article has a summary
     * @return true/false whenever this article has or has not a summary
     */
    public override bool has_summary() {
        return summaryContent != "";
    }

    /** Check if this article has a "visual" (a preview image) */
    public override bool has_visual() {
        return visualUrl != "";
    }

    /** Mark this article as read */
    public override void mark_as_read () {
        FeedlyAPI.get_api ().mark_as_read_entry (this);
    }

    /** Create a new Entry from the given JSON object */
    public static Entry from_json_object(Json.Object object) {
        string id = object.get_string_member ("id");

        string fingerprint = object.get_string_member ("fingerprint");
        string originId = object.get_string_member ("originId");//object.get_object_member("origin").get_string_member ("streamId");
        string author = object.has_member ("author") ? object.get_string_member ("author") : "None";
        string title = object.has_member ("title") ? object.get_string_member ("title") : "No title specified";

        string summaryContent = "";
        string summaryDirection = "";

        if(object.has_member ("summary")) {
            summaryContent = object.get_object_member("summary").get_string_member ("content");
            summaryDirection = object.get_object_member("summary").get_string_member ("direction");
        }
        
        TimeVal published_tv = TimeVal ();
        published_tv.tv_sec = (long) object.get_double_member ("published") / 1000;
        DateTime published = new DateTime.from_timeval_utc (published_tv);

        string visualUrl = "";
        int visualWidth = -1;
        int visualHeight = -1;

        if(object.has_member ("visual")) {
            visualUrl = object.get_object_member ("visual").get_string_member ("url");
            visualWidth = (int) (object.has_member ("width") ? object.get_object_member ("visual").get_int_member ("width") : -1);
            visualHeight = (int) (object.has_member ("height") ? object.get_object_member ("visual").get_int_member ("height") : -1);
        }


        bool unread = object.get_boolean_member ("unread");

        return new Entry(id, fingerprint, originId, author, title,
                summaryContent, summaryDirection, published, visualUrl, visualWidth,
                visualHeight, unread);
    }
}
