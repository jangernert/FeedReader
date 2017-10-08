void main (string[] args) {
    Test.init (ref args);

	Test.add_func ("/feedbinapi/construct", () => {
		var api = new FeedbinAPI("user", "password");
		assert (api != null);
    });

	Test.run ();
}
