public class FeedReader.BazQuxAPI : GLib.Object {

	private BazQuxConnection m_connection;

	private string m_bazqux;
	private string m_userID;

	public BazQuxAPI ()
	{
		m_connection = new BazQuxConnection();
	}


	public LoginResponse login()
	{
		m_connection.getToken();
		return LoginResponse.UNKNOWN_ERROR;
	}

	public bool ping() {
		return Utils.ping("bazqux.com");
	}
}
