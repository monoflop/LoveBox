class ExtendedAsciiHelper {
  //Utf -> Code_page_437
  static const Map<String, String> lookupConversion = {
    //https://en.wikipedia.org/wiki/Code_page_437
    "\u263A": "\u0001",
    "\u263B": "\u0002",
    "\u2665": "\u0003",
    "\u2666": "\u0004",
    //German Umlaute
    "\u00FC": "\u0081",
    "\u00E4": "\u0084",
    "\u00C4": "\u008E",
    "\u00F6": "\u0094",
    "\u00D6": "\u0099",
    "\u00DC": "\u009A",
  };

  static String utfToCp437(String input) {
    String output = input;
    lookupConversion.forEach((key, value) {
      output = output.replaceAll(key, value);
    });
    return output;
  }
}
