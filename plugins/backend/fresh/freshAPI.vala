//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

FeedReader.dbDaemon dataBase;
FeedReader.Logger logger;

public class FeedReader.freshAPI : Object {

	private freshConnection m_connection;
	private freshUtils m_utils;

	public freshAPI()
	{
		m_connection = new freshConnection();
		m_utils = new freshUtils();
	}

	public LoginResponse login()
	{
		logger.print(LogMessage.DEBUG, "fresh backend: login");

		if(!Utils.ping(m_utils.getUnmodifiedURL()))
			return LoginResponse.NO_CONNECTION;

		return m_connection.getToken();
	}

}
