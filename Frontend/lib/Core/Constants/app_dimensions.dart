class AppDimensions {
  AppDimensions._(); // Private constructor to prevent instantiation

  // ── Spacing ───────────────────────────────────────────────────────────
  static const double xs =
      4.0; // xs is extra small, used for tight spacing between elements
  static const double sm =
      8.0; // sm is small, used for general spacing between elements
  static const double md =
      12.0; // md is medium, used for larger spacing between sections
  static const double lg =
      16.0; // lg is large, used for significant spacing between major sections for example between the header and the content
  static const double xl =
      20.0; // xl is extra large, used for very large spacing between major sections or to create a sense of separation
  static const double xxl =
      24.0; //  xxl is extra extra large, used for maximum spacing between major sections or to create a strong sense of separation
  static const double xxxl =
      32.0; // xxxl is extra extra extra large, used for maximum spacing between major sections or to create a strong sense of separation

  // ── Border radius ─────────────────────────────────────────────────────
  static const double radiusSm =
      8.0; // radiusSm is small, used for buttons and input fields
  static const double radiusMd =
      12.0; // radiusMd is medium, used for cards and larger containers
  static const double radiusLg =
      16.0; // radiusLg is large, used for larger cards and containers
  static const double radiusXl =
      20.0; // radiusXl is extra large, used for very large containers
  static const double radiusXxl =
      28.0; // radiusXxl is extra extra large, used for maximum rounded corners
  static const double radiusFull =
      100.0; // radiusFull is full, used for circular elements

  // ── Component sizes ───────────────────────────────────────────────────
  static const double buttonHeight =
      52.0; // buttonHeight is the standard height for buttons, providing a comfortable touch target for users
  static const double inputHeight =
      56.0; // inputHeight is the standard height for input fields, ensuring they are easily tappable and visually balanced
  static const double navBarHeight = 65.0;
  static const double avatarSm = 28.0;
  static const double avatarMd = 36.0;
  static const double avatarLg = 44.0;
  static const double courtCardHeight = 220.0;
  static const double courtPhotoHeight = 120.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;

  // ── Page padding ──────────────────────────────────────────────────────
  static const double pagePaddingH =
      20.0; // pagePaddingH is the horizontal padding for pages, ensuring content is not too close to the edges of the screen
  static const double pagePaddingV =
      16.0; // pagePaddingV is the vertical padding for pages, providing consistent spacing between sections of content
}
