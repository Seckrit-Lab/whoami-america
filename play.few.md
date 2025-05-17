``` few ```
# OpenTADA - Play

## Generated Files
- lib/models/book.dart
- lib/agents/director.dart
- lib/agents/conductor.dart
- lib/agents/scribe.dart
- lib/agents/artist.dart
- lib/play_session.dart
- lib/log_screen.dart

## Play Structure
A play session involves the use of a book in Tada book format (described below) and the following agents, each managing its LLM interactions:
- Director
- Conductor
- Scribe
- Artist
There is also an application log, which is just a long, running text string.
The Director, Conductor, and Scribe use the `gemini-1.0-pro` model (or a similar compatible Gemini model like `gemini-flash` as implemented). The Artist uses the OpenAI DALL-E 3 model for image generation, accessed via the `openai_dart` library.
Any time a message is sent to, or a response received from, any of these agents or the player, it will be logged to the application log in the format "[Agent Name or 'Player'] to [Agent name or 'Player']: [Message]"

## Book Format
A Tada book is a JSON file with the extension .tada.json. Examples can be found in the books file of this repo. The format is as follows:
- A headline at the start of the file gives the title of the book.
- A Characters section with a list of characters, giving names and descriptions of both appearance and personality.
- A Setting, describing the overall scenario. Detailed location descriptions are not necessary and should go into Locations. This encompasses a broader description of the situation, e.g. for The Grapes of Wrath, this might indicate "The 'Dustbowl' of early twentieth century America, viewed through the eyes of a family traveling in a desperate search for work."
- Outcomes, which defines successful or unsuccessful end states for the novel.

## Agents
### Director
- The Director is persistent throughout the play session, never being reset between sequences like the other agents.
- The Director is responsible for reading and validating the entire contents of the book file. If it does not match the format described in "Book Format", a text message will be shown in the play window describing the problem and asking the player to contact the author for help. All other functions then stop.

### Conductor
- Manages player preferences and overall narrative flow between scenes.

### Scribe
At the beginning of a scene, a new Scribe is instantiated. The Director, after consulting with the Conductor regarding player preferences and mood, will instruct the Scribe as follows. The Scribe's response will be displayed in the main text window, and subsequent player responses will be directed to the Scribe.

"You are the scribe for a Tada text adventure game. Take any further inputs as player actions in a text adventure game akin to Zork. Respond to player inputs by describing the actions, dialogue, and scenes resulting from the player actions specified. Do not deviate from this process for the remainder of this conversation."

### Artist
The Artist connects to an image generation AI (OpenAI DALL-E 3). When prompted by the Scribe, Conductor, or Director, the Artist will render the image that they request, considering any specified art style. This is shown in the image area of the play window.

## Open Book
When a book is opened, it is added as a file to the context of the Director LLM session and the Director is informed of their role as follows:
"You are the Director of a text adventure play session. (insert Tada book format description here) You are able to speak to a CONDUCTOR, SCRIBE, and ARTIST by prefacing your responses with their title. E.g. to tell the artist to render a picture of a cube, say 'ARTIST: Draw a cube.' A response without such a preface is assumed to be a message directly to the player. A response reading only "OK" is taken to mean that control should be delegated to the appropriate other agent, which is usually the SCRIBE.

First, validate the given book file to ensure it suits the Tada book format. If it is not valid, indicate this to the player and stop following these instructions.

Next, confirm with the CONDUCTOR that it knows the player's preferred art and writing styles. If it does not, ask the player to provide this information in the voice of a character in the book or an invented character inspired by the setting.

Next, tell the ARTIST to render a title screen that includes the literal text of the book title. Give the ARTIST a description of the book setting and, optionally, 1 to 3 prominent characters and optionally a single notable location. Use the player's preferred art style if provided."

This will cause a title screen to be rendered and displayed.