# Event Design Process

How an event is put together (heromedel, 2026-10-23). Every new event's text, outcomes and messages are checked
against `lore-facts.md`.

| Step | Do | Sources |
|---|---|---|
| 1 | Decide what band, type of cluster and type of event the event is for. | GDD 2G, 2H, 2J, 2K, 2O |
| 2 | Decide which cluster states it works in. | GDD 2L, 2R |
| 3 | Decide what options it leads to, such as battle, trade, escape, a reward or a choice of rewards, and which blue choices can alter it. | GDD 3O (Hail); race profiles (crew traits, technology) |
| 4 | Decide who or what the event involves or encounters. | Race profiles; `lore-facts.md` |
| 5 | Decide how it is meant to affect the player. | `game-project-standards.md` (design philosophy) |
| 6 | Decide whether its ships or rewards can be adjusted by factors such as the band it is in. | GDD 2N, 8I; `mawjig-cost-table.md` |
| 7 | Decide whether it is meant for specific clusters, such as doomed, Terran, Border or At War. | GDD 2R; race profiles |
| 8 | Decide how the voice should come across, and how any in-game quotes, such as someone speaking, should come across. The informative narrator is generally one voice, and a race speaking is a different one. | Race profiles; `lore-facts.md` (e.g. how the Senti speak) |
| 9 | Write the message lines, questions, choices, outcomes and outcome lines. | The notes below |

Creative steps follow the Creative 3-6 Rule (`CLAUDE.md`). How an event is written down, with examples:
`events-sample.md`.

## Placeholder tags

An event can be outlined with placeholder tags before it is written, for example:

    (race) declares (aggressive message), but is bluffing: they are not as well off as they claim.
    Choices: fight, demand negotiation, or try to flee.
    Outcomes: X, Y, Z, or C if caught fleeing.
    (race D) grants a blue choice ..., which leads to A or B.

This shows the structure only. It has no voice or message flow; those come at step 9.

## Notes: how FTL events read

Notes, not rules: taken from FTL's own event files and from screenshots of the game (2026-10-23).

- **The box:** one block of opening text, a blank line, then numbered choices ("1. Send your crew in a shuttle to
  help put out the fire."). An outcome is a new box: its text, a summary of what was gained or lost, then
  "1. Continue...". Long events are split across boxes with "Continue...".
- **Length:** an opening is two to four short sentences: where you are, what you see, and what is at stake. "You
  find the source of the distress call, a small research station. It appears a small laboratory fire got out of
  control and is threatening to destroy the station. Their fire suppression system is not responding."
- **Narrator:** second person and present tense, plain and informative. "You jump into the middle of a plasma
  storm."
- **Speakers:** a short quote in their own voice, set apart from the narrator. The Engi are telegraphic
  ("Assistance requested. Danger present. Imminent destruction."), a Mantis sneers ("Foolish meatsacks").
- **Choices:** short and in the imperative, from the player's side ("Prepare to board and investigate."). Most
  events offer a way out ("Ignore the ship.", "Leave."). Some choices are spoken by the crew ("Too dangerous.
  We'll just wait for the FTL to charge.").
- **Blue choices:** shown in blue after the ordinary choices, with the requirement in brackets first: "3. (Engi
  Crew) Send your Engi to calm down the infected." A blue choice whose requirement the player doesn't meet isn't
  shown at all: with only an Engi aboard, that event's Rock and Advanced Medbay choices never appeared. The outcome says why the trait works ("It's unlikely the Rock's impressive immune system is
  susceptible to a human virus..."). They are usually safer or better, but not always: in one FTL event sending
  your Engi to negotiate gets it killed.
- **Numbers stay out of the prose:** the text says "you are able to scavenge some supplies from the cargo hold",
  and the summary box shows the amounts. A loss is told in the text ("an unfortunate soul is lost in the inferno")
  and named in the box ("Oni is gone").
- **Every outcome finishes its story** before the reward: what happened, then why it ended that way.
- **Variety:** a plain choice often rolls between a good and a bad outcome, while a blue choice is usually fixed.
  Common events draw their opening from a list of alternatives, so a trap beacon reads differently each time.
- **Humour:** dry and occasional ("calculating insults at you", "the little binary criminal"), never forced.
- **From Federation Home Planet (McCarthy):** each speaker has a voice of their own; a line written for an event
  type must fit every event of that type; pools of interchangeable lines keep the same event from reading the same
  twice.
