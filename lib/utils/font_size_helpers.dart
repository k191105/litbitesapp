double getFontSize(String text) {
  if (text.length > 300) return 20.0;
  if (text.length > 200) return 22.0;
  if (text.length > 120) return 24.0;
  if (text.length > 80) return 26.0;
  return 28.0;
}

double getSourceFontSize(String source) {
  if (source.length > 100) return 15.0;
  if (source.length > 80) return 16.0;
  if (source.length > 60) return 17.0;
  return 18.0;
}
