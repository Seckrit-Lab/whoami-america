``` few ```
# OpenTADA - Main

## Generated Files
- lib/main.dart: Main application entry point and UI implementation for Flutter
- pubspec.yaml: Flutter project definition, dependencies, and assets file

## Project Format
An Interactive Fiction engine that works cross-platform on Windows, MacOS, iOS, and Android; preferably, also Web. Flutter is the chosen platform based on a recommendation from Google Gemini (https://g.co/gemini/share/e58036eb022a). 

Some externals/extensions that may be required in order for this compilation to work include the [Flutter SDK](https://docs.flutter.dev/get-started/install/macos/desktop), XCode, and CocoaPods.
## Core Components

## Implementation Details
The user interface is relatively simple and is as follows:
- During most interactions (story mode):
  - The majority of the interface is taken up by a text area containing the current chapter/sequence thus far
  - A one-line text entry bar at the bottom is used for primary user input
  - A square image that the application occasionally updates appears on screen, differently depending on layout:
    - In landscape view, the image takes up half of the width of the interface and centered vertically.
    - In portrait view, the image takes up half the height of the interface and is centered horizontally.
      - If the user is on a particularly small screen, like a phone, the image appears in the middle of the text at the time that it is rendered, but scrolls off the screen as new text is added. In all other cases, the image remains constant as described above.