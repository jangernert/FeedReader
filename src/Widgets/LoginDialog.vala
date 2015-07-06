public class FeedReader.LoginDialog : Gtk.Dialog {

    public signal void sucess();

    public LoginDialog(OAuth type)
    {
        this.title = "Login";
		this.border_width = 0;
        //this.c(parent);
        this.set_modal(true);
		set_default_size(500, 700);

        var content = get_content_area() as Gtk.Box;
        var WebLogin = new WebLoginPage();
        WebLogin.expand = true;
        WebLogin.success_share.connect(() => {
            sucess();
            this.close();
        });
        content.add(WebLogin);

        WebLogin.loadPage(type);

        show_all();
    }
}
