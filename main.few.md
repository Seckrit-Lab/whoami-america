``` few ```
# OpenTADA - Main

## Generated Files
- lib/main.dart: Main application entry point and UI implementation for Flutter
- pubspec.yaml: Flutter project definition, dependencies, and assets file

## Project Format
An Interactive Fiction engine that works cross-platform on Windows, MacOS, iOS, and Android; preferably, also Web. Flutter is the chosen platform based on a recommendation from Google Gemini (https://g.co/gemini/share/e58036eb022a). 

Some externals/extensions that may be required in order for this compilation to work include the [Flutter SDK](https://docs.flutter.dev/get-started/install/macos/desktop), XCode, and [CocoaPods](sudo gem install cocoapods).
## Core Components

## Implementation Details
### UI
The user interface is relatively simple and is as follows:
- During most interactions (story mode):
  - The majority of the interface is taken up by a text area containing the current chapter/sequence thus far
  - A one-line text entry bar at the bottom is used for primary user input
  - A square image that the application occasionally updates appears on screen, differently depending on layout:
    - In landscape view, the image takes up half of the width of the interface and centered vertically.
    - In portrait view, the image takes up half the height of the interface and is centered horizontally.
      - If the user is on a particularly small screen, like a phone, the image appears in the middle of the text at the time that it is rendered, but scrolls off the screen as new text is added. In all other cases, the image remains constant as described above.
  - A small button on the top-right of the window opens a window in which an application log is displayed. The contents of that log are described primarily in play.few.md.
  - These elements provide the inputs and outputs of a play session as described in play.few.md.
### Function
For the initial implementation, this application will use the Google Gemini API. However, it will eventually be made configurable, with ChatGPT and local ollama being the most important candidates. An API key is in local storage, e.g. in a file called gemini.key or in the value of "geminikey" in a key-value store. If the key is not found in local storage, the user will be prompted for it with a pop-up dialogue, and what they enter will be kept in that local storage. In a later build, there will be no manual provision of API keys.

Once the Gemini key has been found, the user will be prompted to select a file with the extension .tada.json from their local storage, e.g. via the "open file"/Finder interface on MacOS. The contents of that file will be used to begin the game according to the "open book" section of play.few.md. If, at any time, the Gemini API returns a message indicating that a limit has been exceeded, the user will be prompted to provide a new API key.

The user's input will be provided to the LLM and the LLM's responses will be shown in the main text window.