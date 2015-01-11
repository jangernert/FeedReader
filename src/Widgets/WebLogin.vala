

public class WebLogin : Gtk.Dialog {

	private WebKit.WebView m_view;
	private Gtk.ScrolledWindow m_scroll;
	private string m_url;
	private string m_redirect_url;
	public signal void auth_code(string code);
	

	public WebLogin(Gtk.Window window, string serviceName, int serviceType) {
		this.title = "Login to " + serviceName;
		this.border_width = 5;
		GLib.Object (use_header_bar: 1);
		this.set_modal(true);
		this.set_transient_for(window);
		this.set_default_size(700, 800);
		
		switch(serviceType)
		{
			case TYPE_FEEDLY:
				m_url = buildFeedlyURL();
				break;
		}
		
		m_view = new WebKit.WebView();
		m_view.load_changed.connect(redirection);
		m_view.load_uri(m_url);
		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.add(m_view);
		m_scroll.expand = true;

		
		var content = get_content_area ();
		content.add(m_scroll);
		this.show_all();
	}
	
	
	private string buildFeedlyURL()
	{
		string url = base_uri + "/v3/auth/auth" + "?client_secret=" + apiClientSecret + "&client_id=" + apiClientId;
		url = url + "&redirect_uri=" + apiRedirectUri + "&scope=" + apiAuthScope + "&response_type=code&state=getting_code";
		return url;
	}
	
	public void redirection(WebKit.LoadEvent load_event)
	{
		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				string url = m_view.get_uri();
				if(url.has_prefix(apiRedirectUri))
				{
					int start = url.index_of("=")+1;
					int end = url.index_of("&");
					string code = url.substring(start, end-start);
					auth_code(code);
					destroy();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				break;	
			case WebKit.LoadEvent.FINISHED:
				break;
		}
	}


}
