``` few ```
# OpenTADA - Main

## Generated Files
- Program.fs: Main application entry point and UI implementation
- tada.fsproj: .NET project file

## Project Format
An Interactive Fiction engine that works cross-platform on Windows, MacOS, iOS, and Android; preferably, also Web. Google Gemini recommended Uno Platform as a very likely candidate (https://g.co/gemini/share/e58036eb022a). (Flutter was arguably the top recommendation but the original author has a personal preference for .Net and a long-standing familial fondness for the game of Uno; it tracks back through my grandfather the engineer and I find it satisfying to include it in one of my greatest inventive efforts.) 
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