/**
 * Representation model of a subscription.
 */
public abstract class Model.Subscription : Object {
    public string id {get; private set; }
    public string title {get; set; }
    public double velocity {get; private set; }
    public string visualUrl {get; private set; }
    public DateTime updated {get; private set; }
    public string website {get; private set; }
    public Gee.ArrayList<string> category_ids {get; private set; }
    public int unread_count {get; set; default = -1; }

    public Subscription(string id, string title, double velocity, string visualUrl, DateTime updated, string website, Gee.ArrayList<string> category_ids) {
        this.id = id;
        this.title = title;
        this.velocity = velocity;
        this.visualUrl = visualUrl;
        this.updated = updated;
        this.website = website;
        this.category_ids = category_ids;
    }

    /** get number of unread articles associated to this subscription */
    public abstract unowned int get_number_of_unread_articles ();

    /** mark all articles in this subscription as read */
    public abstract void mark_as_read ();

    /** Get all articles associated with this subscription */
    public abstract Gee.ArrayList<Entry> get_entries ();

}