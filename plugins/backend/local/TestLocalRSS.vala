using FeedReader;

void main(string[] args)
{
	Test.init(ref args);
	
	Test.add_data_func ("/Rfc822/parseDate/Basic", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 2006 23:59:45 +0000");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/LowerCase", () => {
		var date = Rfc822.parseDate("thu, 09 feb 2006 16:59:45 mst");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/UpperCase", () => {
		var date = Rfc822.parseDate("THU, 09 FEB 2006 16:59:45 MST");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/LotsOfWhiteSpace", () => {
		var date = Rfc822.parseDate("  \t\n Thu, \t\n 09 \t\n Feb \t\n 2006 \t\n 23:59:45 \t\n +0000 \t\n");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear2000", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 00 23:59:45 +0000");
		assert(new DateTime.utc(2000, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear2006", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 06 23:59:45 +0000");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear2049", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 49 23:59:45 +0000");
		assert(new DateTime.utc(2049, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear1950", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 50 23:59:45 +0000");
		assert(new DateTime.utc(1950, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear1956", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 56 23:59:45 +0000");
		assert(new DateTime.utc(1956, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/TwoDigitYear1999", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 99 23:59:45 +0000");
		assert(new DateTime.utc(1999, 2, 9, 23, 59, 45).equal(date));
	});
	
	// Just in case we get RSS feeds made by Romans
	Test.add_data_func ("/Rfc822/parseDate/ThreeDigitYear", () => {
		var date = Rfc822.parseDate("Thu, 09 Feb 156 23:59:45 +0000");
		assert(new DateTime.utc(156, 2, 9, 23, 59, 45).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/OnlyRequired", () => {
		var date = Rfc822.parseDate("09 Feb 2006 23:59 +0000");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 0).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/OneDigitDay", () => {
		var date = Rfc822.parseDate("9 Feb 2006 23:59 +0000");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 0).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/UnsupportedZone", () => {
		var date = Rfc822.parseDate("09 Feb 2006 23:59 X");
		assert(new DateTime.utc(2006, 2, 9, 23, 59, 0).equal(date));
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingDay", () => {
		var date = Rfc822.parseDate("Feb 2006 23:59 +0000");
		assert(date == null);
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingMonth", () => {
		var date = Rfc822.parseDate("09 2006 23:59 +0000");
		assert(date == null);
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingYear", () => {
		var date = Rfc822.parseDate("09 Feb 23:59 +0000");
		assert(date == null);
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingHour", () => {
		var date = Rfc822.parseDate("09 Feb 2006 59 +0000");
		assert(date == null);
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingMinute", () => {
		var date = Rfc822.parseDate("09 Feb 2006 23 +0000");
		assert(date == null);
	});
	
	Test.add_data_func ("/Rfc822/parseDate/MissingZone", () => {
		var date = Rfc822.parseDate("09 Feb 2006 23:59");
		assert(date == null);
	});
	
	Test.run ();
}
