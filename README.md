# tada
OpenTADA, for Open-Source Text Adventure Diamond Age, is a multi-agent AI rework of the text adventure genre of which Colossal Cave was the debut and Zork remains the archetype. Yes, "Diamond Age" comes from the Stephenson novel and I thank my brother Buck for introducing me to it!

# Design
OpenTADA defines a simple language by which multiple AI agents can communicate to coordinate an enjoyable interactive fiction experience. These include:
- Gxd: Any interactions between other agents that they cannot mediate will be resolved by Gxd. If Gxd fails, the game ends in a fashion appropriate to the setting. For example, in a Discworld setting, Cohen the Barbarian reaches Cori Celesti with his bomb. Has access to stage directions, dramatis personae, and script for entire work.
- Conductor: Combining the metaphors of an orchestra and a train conductor, organizes the work of the remaining "non-divine" agents. Has access to stage directions, dramatis personae, and script for current sequence.
- Director: Monitors player's sentiment and progress. If player is not making progress toward end-of-scene goals or expresses frustration, signals Writer to provide hints. If player expresses boredom, signals Writer to invoke more exciting events. Has access to stage directions and dramatis personae, but not script, for current sequence.
- Writer: Generates text based on original script and player input. Not responsible for player sentiment or progress. Has access to script and dramatis personae, but not stage directions, for current sequence.

The information that comprises an OpenTADA novel includes the following; Gxd gives them as needed to the conductor, who gives subsets of them to the writer and director as needed:
- Script: A description of important events in a given scene, including actions taken by characters not in Dramatis Personae and natural occurrences, as well as scenery descriptions.
- Dramatis Personae: A list of characters including names, physical descriptions, important knowledge, important dialogue, history, relationships, etc.
- Stage Directions: Actions that can or must be taken by non-player characters in a given sequence.

An OpenTADA session also requires player information. This can be given loosely as an AI prompt describing the player and what they want from the session, but important details for a good session include:
- Vocabulary level (in the language of the novel)
- Preferred writing style (e.g. as a list of favorite authors)
- Desired interaction level (basically just read, or choreograph dancing and fight sequences?)

Without getting into details like API specifications, please give a basic description of how the interactions of this system work -- at what point does the application provide what parts of the novel to which agents, when do they interact with each other, and what simple language do they use to do so? E.g. does the Director read each input from the player and send PLAYER MAD to Writer to suggest it's time to simplify things?

# Prototype
This is the example prompt that was used to prototype this process on Google Gemini to help make sure an old friend doesn't have a schism with his visual novelist daughter over AI (though actually I think they're OK). Try pasting it into Google Gemini or the LLM of your choice and tweaking the "the player is" statement to match yourself!

Serafina’s Diamond Age

Please read the following description of an OpenTADA text adventure game. Understanding the setting and characters, please render an image in watercolor style of scene 1. Take any further inputs as player actions in a text adventure game akin to Zork. When the action moves to a different scene, or what has just happened differs significantly from what was last rendered as an image, render a new image. Otherwise, respond by describing the actions, dialogue, and scenes resulting from the player actions specified. Do not deviate from this process for the remainder of this conversation.

Player Character: JJ Abromawitz (see below)

Setting: Somewhere in the USA, 2025.

Characters:
Serafina Abromawitz: An acclaimed novelist. Her work is the intersection of John Steinbeck and Cormac McCarthy. She is enamored of the humanity, the realness, of literature. Large language models upset her because, as she sees it, they steal from real human authors.

Joseph Abromawitz: A world-class computer programmer. He has collaborated with his daughter, the aforementioned Serafina, before. However, they are at odds because his work on artificial intelligence conflicts with Serafina’s literary ideals. He wants to work with her again, or at least extract the wedge that AI and the way that society views it has driven between them.

JJ Abromawitz: (For Joseph Junior) Son of Joseph, younger brother of Serafina.

Bill Gambler: A friend and former colleague of Joseph. Bill is a computer programmer and hacker who has spent time in prison and in mental hospitals. He has a moderate view of Large Language Models as a tool to facilitate human communication and connection in an unprecedented way. When Joseph calls him, his words may help to bring the two together — either by wisely counseling them to resolve their differences, or by being so strange that their differences seem trivial in comparison.

Outcomes:
- Eventually, Joseph and Serafina reach a better understanding or at least detente.

Scenes:
- (Start) Serafina is upset at how Joseph’s AI job has put them at odds.


The player is a huge Star Wars fan and will be sharing the results with his child. The text should be simple and appropriate for a fourth-grade reading level. Images should be photorealistic style.


Start by describing scene 1 and rendering an image of it.
