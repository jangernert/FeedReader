/**
 * Representation model of a subscription.
 */
public class Subscription : Model.Subscription,Gee.Comparable<Subscription> {
   
    public Subscription(string id, string title, double velocity, string visual_url, DateTime updated, string website, Gee.ArrayList<string> category_ids) {
        base (id, title, velocity, visual_url, updated, website, category_ids);
    }

    /** get number of unread articles associated to this subscription */
    public override unowned int get_number_of_unread_articles () {
        return FeedlyAPI.get_api ().get_count_of_unread_articles (id);
    }

    /** mark all articles in this subscription as read */
    public override void mark_as_read () {
        FeedlyAPI.get_api ().mark_as_read_subscription (this);
    }

    /** Get all articles associated with this subscription */
    public override Gee.ArrayList<Entry> get_entries () {
        return FeedlyAPI.get_api ().get_entries_for_subscription (this);
    }

    public int compare_to (Subscription other) {
        if (unread_count <= 0 && other.unread_count > 0) return 1;
        else {
            if (title == other.title) return 0;
            if (title < other.title) return -1;
            else return 1;
        }
    }
        
    /** Create a new subscription from the given JSON object */
    public static Subscription from_json_object (Json.Object object) {
        try {
        DateTime updated_date;      
        if (object.has_member ("updated")) {
            TimeVal update_tv = TimeVal ();
            update_tv.tv_sec = (long) object.get_double_member ("updated") / 1000;
            updated_date = new DateTime.from_timeval_utc (update_tv);
        } else
            updated_date = new DateTime.now (new TimeZone.local ());

        Gee.ArrayList<string> category = new Gee.ArrayList<string> ();

        Json.Array array = object.get_array_member ("categories");

        for(int i = 0; i < array.get_length(); i++) {
            Json.Object ob = array.get_object_element (i);

            category.add (ob.get_string_member ("id"));
        }
        var id = object.get_string_member ("id");
        var title = object.get_string_member ("title");
        double velocity = object.has_member ("velocity") ? object.get_double_member ("velocity") : -1.0;
        var v_url = object.has_member ("visualUrl") ? object.get_string_member ("visualUrl") : "";
        var website =  object.has_member ("website") ? object.get_string_member ("website") : "";
        return new Subscription(id, title, velocity, v_url, updated_date, website, category);
        } catch (Error e) {
            debug ("failed to parse "+e.message);
        }
        
    }
}