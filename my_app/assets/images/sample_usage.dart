// Example of how to use images in your Flutter app

// 1. Place your image files in assets/images/ folder
// 2. Make sure they're listed in pubspec.yaml under assets
// 3. Use them in your code like this:

/*
// Display an image from assets
Image.asset(
  'assets/images/your_image.png',
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)

// Use as background
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/background.jpg'),
      fit: BoxFit.cover,
    ),
  ),
)

// Use in AppBar
AppBar(
  title: Row(
    children: [
      Image.asset('assets/images/logo.png', height: 30),
      SizedBox(width: 8),
      Text('A_Dairy'),
    ],
  ),
)
*/