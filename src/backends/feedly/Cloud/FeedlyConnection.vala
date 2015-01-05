/**
 * Representation of a connection to Feedly
 */
public class FeedlyConnection {
    private const string base_uri = "http://cloud.feedly.com";
    private string access_token;

    public FeedlyConnection (string token) {
        this.access_token = token;
    }

    public string send_get_request_to_feedly (string path) {
         return send_request (path, "GET");
    }

    public string send_post_request_to_feedly (string path, Json.Node root) {
        var session = new Soup.Session ();
        var message = new Soup.Message ("POST", base_uri+path);
        
        var gen = new Json.Generator();
        gen.set_root(root);
        message.request_headers.append ("Authorization","OAuth %s".printf(access_token));

        size_t length;
        string json;
        json = gen.to_data(out length);
        message.request_body.append(Soup.MemoryUse.COPY, json.data);
        session.send_message (message);
        return (string) message.response_body.flatten().data;
    }
    
    public string send_post_string_request_to_feedly (string path, string input, string type){
        var session = new Soup.Session ();
        var message = new Soup.Message ("POST", base_uri+path);
        
        message.request_headers.append ("Authorization","OAuth %s".printf(access_token));
        message.request_headers.append ("Content-Type", type);

        message.request_body.append(Soup.MemoryUse.COPY, input.data);
        session.send_message (message);
        return (string) message.response_body.flatten().data;

    }

    public string send_delete_request_to_feedly (string path) {
        return send_request (path, "DELETE");
    }

    private string send_request (string path, string type) {
        var session = new Soup.Session ();
        var message = new Soup.Message (type, base_uri+path);
        message.request_headers.append ("Authorization","OAuth %s".printf(access_token));
        session.send_message (message);
        return (string) message.response_body.data;
    }
}
