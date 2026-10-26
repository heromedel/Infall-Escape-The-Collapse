"""Shared colours for Infall art. The art tools import these so a shared colour is set in one place; palette.md lists
them with what each is for."""

POWER_GREEN = "#66ff66"   # powered systems, power bars, and the symbol on an intact player system
PIRATE_POWER_ORANGE = "#ff8500"   # as vivid as power green: the most saturated orange at the nearest lightness

MECHA_POWER_PURPLE = "#aa28eb"   # the Mecha's accent: visor, chest lights, their power
TENTAURI_POWER_PINK = "#ff5eca"   # the Tentauri's power colour, "bubblegum matched"

# the Mecha crew palette (mecha/crew/), darkest first
MECHA = {
    "outline": "#0a0a0e",
    "shadow": "#1c1d24",
    "armour dark": "#2e3039",
    "armour": "#4a4d5a",
    "armour edge": "#7a7f8e",
    "power purple": MECHA_POWER_PURPLE,
    "purple deep": "#5a128c",
    "purple pale": "#ebe1fa",
    "purple white": "#f5ebff",
}
