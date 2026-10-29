## How to Play: the rules on one scrolling page, in the order a new captain needs them.
class_name RulesScreen
extends Control

signal back

const RULES := """[font_size=30][b]How to Play[/b][/font_size]

[color=#ffb347][b]The goal[/b][/color]
Bring the enemy's [b]hull to 0[/b] or kill their whole crew. A destroyed ship is stamped DESTROYED and its systems wreck; a crewless one is DERELICT. Then the battle goes on for you alone: with no enemy left the Jig Drive charges at once if Engines and Piloting work, so you can [b]JUMP[/b] right away or stay to repair, fight fires and heal first. In a run, your ship carries into the next battle exactly as you left it.

[color=#ffb347][b]Your deck is your ship[/b][/color]
Every system puts cards in your deck: the Reactor adds [b]Power Cells[/b], Shields add [b]Raise Shield[/b], each weapon system adds its weapon cards, Life Support adds [b]Restore Environment[/b], and so on. Every crew member adds [b]Repair[/b] and, with Airlock Control, [b]Cycle Airlock[/b]. Cards are never discarded: when a card leaves play it is shuffled back into your deck. A [b]broken[/b] system's cards can't be drawn until it is repaired.

[color=#ffb347][b]A turn[/b][/color]
1. Start of turn: cloaks and burns end, the Med Bay heals.
2. Your power recharges.
3. Draw a card, plus any extra cards your crew earn (below).
4. Play cards and move crew, in any order.
5. End of turn: unspent power burns in Engines (Auto Burn), the Jig Drive charges, fires burn and spread, breaches choke, air runs down if Life Support is down, boarders sabotage.

[color=#ffb347][b]Jumping[/b][/color]
The Jig Drive needs {charges} charges. At the end of each turn you burn at least 1 power in Engines, it gains a charge per working Engines level, as long as Engines and Piloting work. Press [b]JUMP[/b] when it is full; jumping needs a pilot in Piloting, or Auto Pilot (level 2+).

[color=#ffb347][b]Power[/b][/color]
Play a [b]Power Cell[/b] from your hand to put it in your power row; it stays there all battle. Spending power flips cells; they recharge at the start of your turn. Damage to the Reactor takes cells offline. If you play no cards at all in a turn, you can [b]Reroute Power[/b]: a Power Cell from your deck comes into play, the deck is shuffled, and your turn ends.

[color=#ffb347][b]System limits[/b][/color]
A system's level is how much power its cards can use in one turn. Damage lowers it; a system with all its levels damaged is broken. Ion and hacks take a system offline through its captain's next turn. A weapon's [b]Type[/b] is its power cost.

[color=#ffb347][b]Evasion[/b][/color]
Engines dodge only when powered: burn power in them (click BURN on the Engines tile, or leave power unspent with Auto Burn). In Classic mode, 1 burn gives 5%, 2 give 10%, up to the Engines level. A pilot is needed to dodge at all (unless Auto Pilot), and a pilot and an engineer each add 5/7/10% while the engines run. Cloaking adds 40%.

[color=#ffb347][b]Shooting[/b][/color]
Play a weapon card, then click an enemy system. Each shot can miss against the target's evasion. A hit damages the system and the hull, and may wound the crew inside.
• Lasers, chain repeaters and ion: each shield layer stops one shot and drops.
• Torpedoes ignore shields but use missiles; beams never miss, but each shield layer cuts their damage.

[color=#ffb347][b]Ammo and Mawjig[/b][/color]
By default every shot and battlesuit launch costs Mawjig: the amount is on the card (for example 0.06 M for a three-bolt laser). Enemies pay for theirs too. Settings has other Ammo modes: Classic (limited missiles and battlesuit parts, other weapons free), Limited Missiles Only, and Missiles Use Mawjig.

[color=#ffb347][b]Shields[/b][/color]
[b]Raise Shield[/b] costs 1 power; that power cell stays under the layer until the layer is hit. You can hold one layer per working Shields level.

[color=#ffb347][b]Crew[/b][/color]
Click one of your crew, then a green system, to move them (once per turn). Hover a crew member to see their skills: Piloting, Engines, Shields, Weapons, Repair and Combat, each untrained, Veteran or Master.
• Shields may draw an [b]extra Raise Shield[/b] each turn (10% per working level). Crew working Shields or a weapon add 10/15/20% by skill: the system recharging faster.
• Crew in a damaged, breached or burning system may draw an extra Repair.
• A manned Sensors or Airlock Control works one level higher; its top level is only reached manned.
• [b]Repair[/b] needs a free crew member in the system and no enemies in it. It fixes one thing: the fire first, then the breach, then damage. The repairer stays in that system for the rest of the turn. Each crew member does one Repair per turn (a repair Master can do two).
• Crew who did anything else can still move once, and they man the system they move to.
A crew member dies at their third wound; the Med Bay heals them.
[b]Experience:[/b] crew learn by doing. Dodging trains the pilot and engineer, popped shield layers the shield crew, firing the gunners, repairing the repair skill and fighting the combat skill. 100 XP makes a Veteran, 150 more a Master. Hover a crew member to see their progress.

[color=#ffb347][b]Hazards[/b][/color]
[b]Fire[/b] damages its system and wounds everyone inside at the end of your turn, and may spread to the system beside it. It burns out when its system is broken, and may choke out once the air is gone. [b]Breaches[/b] (a red hole on the tile) wound everyone inside each turn; a Repair seals them. [b]Air:[/b] each Life Support level holds 1 pip of air. While Life Support is broken or offline, each turn uses a pip; once the air is gone, all your crew take a wound each turn. Working Life Support refills a pip each turn, and [b]Restore Environment[/b] refills one any time. Venting a system through the airlock (no crew needed, just a working Airlock Control) puts out its fire but kills anyone in it.

[color=#ffb347][b]Airlock Control[/b][/color]
From level 2, each level makes enemy boarders take a turn longer to force their way from one system to another (teleporting isn't slowed). Each level makes fire spread less often.

[color=#ffb347][b]Tactics[/b][/color]
[b]Teleport[/b] sends crew to either ship: boarders damage their system and the hull each enemy turn. [b]Mind Control[/b] turns an enemy against their own ship for a turn. [b]Hack[/b] shuts a system down. [b]Battlesuits[/b] from an EVB Dock fight on their own for 3 turns.

[color=#ffb347][b]Sensors[/b][/color]
Level 1 shows enemy crew, 2 their power, 3 their weapon cards, 4 (level 3 manned) their whole hand.

[color=#ffb347][b]Runs and Mawjig[/b][/color]
After you jump, Continue Run takes your ship to a random enemy. A beaten enemy pays salvage: 2.5% of its ship's value, 30% more if you killed its crew. Each jump costs 1.21 Mawjig. Between battles you can repair hull, buy missiles and hire crew.

[color=#ffb347][b]Controls[/b][/color]
Click a card to play it; aimed cards then need a target. Right-click or Esc cancels. Space ends your turn. Hover anything for details. Battle logs are saved; Settings has a button to open their folder.

[color=#ffb347][b]Rules this prototype adds[/b][/color] [color=#8e98b5](each can be changed in Settings or the XML files)[/color]
• Engine Efficiency (Classic or Extra Burn) and Auto Burn.
• Jump Escape: jumping away mid-battle is allowed.
• Crew Fights: boarders and defenders in the same system trade wounds each turn.
• Each crew member can do one crew card per turn.
• Ion and hacks on a Reactor knock one Power Cell loose instead of shutting it down.
• Fire spreads to the neighbouring tile; tiles stand in for rooms until ships have floor plans.
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
	text.text = RULES.replace("{charges}", str(Catalog.rule("jump", "chargesNeeded", 24)))
	text.add_theme_font_size_override("normal_font_size", 17)
	text.add_theme_font_size_override("bold_font_size", 17)
	panel.add_child(UiKit.margin(text, 10))
