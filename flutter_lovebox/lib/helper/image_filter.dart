class ImageFilter {
  int threshold;
  int brightness;
  int contrast;
  bool grayscale;
  bool inverted;
  bool sobel;

  ImageFilter(
      {this.threshold = 127,
      this.brightness = 0,
      this.contrast = 100,
      this.grayscale = false,
      this.inverted = false,
      this.sobel = false});
}
