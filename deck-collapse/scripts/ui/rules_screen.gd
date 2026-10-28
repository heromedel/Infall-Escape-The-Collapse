## How to Play: the rules on one scrolling page, in the order a new captain needs them.
class_name RulesScreen
extends Control

signal back

const RULES := """[font_size=30][b]How to Play[/b][/font_size]

[color=#ffb347][b]The goal[/b][/color]
Bring the enemy's [b]hull to 0[/b] or kill their whole crew. They'll try the same. A captain can also spool their jump drive and escape.

[color=#ffb347][b]Your deck is your ship[/b][/color]
Every system puts cards in your deck: the Reactor adds [b]Power Cells[/b], Shields add [b]Raise Shield[/b], each weapon system adds its weapon cards, and so on. Every crew member adds [b]Repair[/b], [b]Extinguish Fire[/b] and, with Airlock Control, [b]Cycle Airlock[/b]. Cards are never discarded: when a card leaves play it is shuffled back into your deck.

[color=#ffb347][b]A turn[/b][/color]
1. Start of turn: cloaks and burns end, the Med Bay heals.
2. Your power recharges.
3. Draw a card.
4. Play cards and move crew, in any order.
5. End of turn: fires burn, breaches choke, boarders sabotage.

[color=#ffb347][b]Power[/b][/color]
Play a [b]Power Cell[/b] from your hand to put it in your power row; it stays there all battle. Spending power flips cells; they recharge at the start of your turn. Damage to the Reactor takes cells offline. If you play no cards at all in a turn, you can [b]Reroute Power[/b]: a Power Cell from your deck comes into play, the deck is shuffled, and your turn ends.

[color=#ffb347][b]System limits[/b][/color]
A system's level is how much power its cards can use in one turn. Damage lowers it; a system with all its levels damaged is broken. Ion and hacks take a system offline through its captain's next turn. A weapon's [b]Type[/b] is its power cost, so a damaged weapon system may be unable to fire.

[color=#ffb347][b]Shooting[/b][/color]
Play a weapon card, then click an enemy system. Each shot can miss against the target's [b]evasion[/b] (Engines, a pilot, burns and cloaking). A hit damages the system and the hull.
• Pulse and heavy lasers, chain repeaters and ion: each shield layer stops one shot and drops.
• Torpedoes ignore shields but use missiles.
• Beams never miss, but each shield layer cuts their damage.

[color=#ffb347][b]Shields[/b][/color]
[b]Raise Shield[/b] costs 1 power; that power cell stays under the layer until the layer is hit. You can hold one layer per working Shields level.

[color=#ffb347][b]Crew[/b][/color]
Click one of your crew, then a green system, to move them (once per turn). Crew in a system give a bonus: weapons hit more often, Piloting and Engines add evasion, and Sensors 3 manned reveals the enemy's hand. Crew cards need a free crew member in the system. Each crew member can do one crew card per turn. A crew member dies at their third wound; the Med Bay heals them.

[color=#ffb347][b]Hazards[/b][/color]
[b]Fire[/b] damages its system and wounds everyone inside at the end of your turn. [b]Breaches[/b] wound everyone inside; Restore Environment seals them. If [b]Life Support[/b] is broken or offline, all your crew take a wound each turn. Venting a system through the airlock puts out its fire but kills anyone in it.

[color=#ffb347][b]Tactics[/b][/color]
[b]Teleport[/b] sends crew to either ship: boarders damage their system and the hull each enemy turn. [b]Mind Control[/b] turns an enemy against their own ship for a turn. [b]Hack[/b] shuts a system down. [b]Cloak[/b] adds 40% evasion. [b]Battlesuits[/b] from an EVB Dock fight on their own for 3 turns.

[color=#ffb347][b]Sensors[/b][/color]
Level 1 shows enemy crew. Level 2 shows their power. Level 3 shows their weapon cards; with a crew member there, their whole hand.

[color=#ffb347][b]Controls[/b][/color]
Click a card to play it; aimed cards then need a target. Right-click or Esc cancels. Space ends your turn. Hover anything for details.

[color=#ffb347][b]Rules this prototype adds[/b][/color] [color=#8e98b5](each can be changed in Settings or the XML files)[/color]
• Engine Burn: spend 1 power on Engines for +5% evasion until your next turn.
• Jump Escape: Spool Jump Drive cards build charges; at 3 you jump away.
• Crew Fights: boarders and defenders in the same system trade wounds each turn.
• Each crew member can do one crew card per turn.
• Ion and hacks on a Reactor knock one Power Cell loose instead of shutting it down.
"""


func _ready() -> void:
	add_child(Starfield.new())
	var root := UiKit.vbox(10)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 140
	root.offset_right = -140
	root.offset_top = 22
	root.offset_bottom = -22
	add_child(root)
	root.add_child(UiKit.button("‹ Back", func(): back.emit(), 17))
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.94))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.text = RULES
	text.add_theme_font_size_override("normal_font_size", 17)
	text.add_theme_font_size_override("bold_font_size", 17)
	panel.add_child(UiKit.margin(text, 10))
