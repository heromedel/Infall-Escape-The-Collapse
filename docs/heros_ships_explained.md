Ship Setup - Highly Likely 

Despite how the current art is set up the actual setup of how a ship would be loaded into a game would probably be something like this. 

1. Most Important - Floor Layout

I imagine a series of coordinates in an xml file specify from the center point where rooms, doors and systems are located 

For example 

Room 0: 
(-1,-1),(1,1)

would make a 2x2 room with four tiles
(-1,-1),(-1,1),(1,-1),(1,1)

Without any provided art work the game could still render walls around the room and grey tiles for the floor. 

Then to add a system the xml would have

Piloting(-1,-1)
     Location: North Wall
     Rotation: None
     Mirror: None
     Art: Tentauri.Pilot.Hood
Weapons(-1,1)
    Art: None


Now based on these you can see that the Piloting would go in the room we defined in the top left square and be by the north wall but did not get rotated but would load the Tentauri artwork for the piloting system

But the weapon system didn't get defined as well it will go in the same room, top right corner but would end up as just a system icon over the center of the tile with no console graphic. 

Door 0: (1,1)
    Facing: South
Door 1: (1,1,)
    Facing: East

would put a door in the same room, bottom right corner, on the south wall, and another same corner on the east wall. 


These are all approximate examples and would be defined in xml

the corresponding art work would need to be in the same folder


it should typically then have a hull art work 
and can have an extra floor artwork 

these could all be zipped or just left in a folder with the ships name

other data like the ships hull durability
hull artwork offset
starting weapons and crewmembers

can all be defined in the same xml. 


I think when you compare this to the artwork tests we have done you can see how the art represents it but got out of hand going in its own directions 


One key thing, the game can technically handle a ship with no defined hull, no defined console art, no defined floor art and would simply build the rooms of walls, floor squares, icons right over the tiles and door rectangles. 

Possibly even using default numbers for the hull durability or placing systems any where they fit if not specified where they go

however if a system is not listed the ship is assumed to not have it, thus if the xml doesn't list life support, the crew will probably asphyxiate.
