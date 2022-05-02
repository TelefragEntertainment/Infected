#define ShowModName 0
#define ModName "Infected"


#define FirstDefineMap(_bspname,_maptitle) if(mapname == ##_bspname && title == ##_maptitle) { return ##_maptitle" ("ModName")"; }
#define DefineMap(_bspname,_maptitle) else FirstDefineMap(_bspname,_maptitle)
#define OverrideDefineMap(_bspname,_maptitle) else if(mapname == ##_bspname) { return ##_maptitle" ("ModName")"; }

string(string title) GetMapName =
{
    #if ShowModName == 1

    // Id1 maps
	FirstDefineMap("base32b","Base 32")
    DefineMap("death32c","Death 32")
    DefineMap("dm1","Place of Two Deaths ( Infected! )")
    DefineMap("dm2","Claustrophobopolis ( Infected! )")
    DefineMap("dm3","The Abandoned Base ( Infected! )")
    DefineMap("dm4","The Bad Place ( Infected! )")
    DefineMap("dm5","The Cistern ( Infected! )")
    DefineMap("dm6","The Dark Zone ( Infected! )")
    DefineMap("dm7","The Edge ( Infected! )")
    DefineMap("dm8","Acrophobia ( Infected! )")
    DefineMap("e1m1","The Slipgate Complex ( Infected! )")
    DefineMap("e1m2","Castle of the Damned ( Infected! )")
    DefineMap("e1m3","The Necropolis ( Infected! )")
    DefineMap("e1m4","The Grisly Grotto ( Infected! )")
    DefineMap("e1m5","Gloom Keep ( Infected! )")
    DefineMap("e1m6","The Door To Chthon ( Infected! )")
    DefineMap("e1m7","The House of Chthon ( Infected! )")
    DefineMap("e1m8","Ziggurat Vertigo ( Infected! )")
    DefineMap("e2m1","The Installation ( Infected! )")
    DefineMap("e2m2","The Ogre Citadel ( Infected! )")
    DefineMap("e2m3","The Crypt of Decay ( Infected! )")
    DefineMap("e2m4","The Ebon Fortress ( Infected! )")
    DefineMap("e2m5","The Wizard's Manse ( Infected! )")
    DefineMap("e2m6","The Dismal Oubliette ( Infected! )")
    DefineMap("e2m7","The Underearth ( Infected! )")
    DefineMap("e3m1","Termination Central ( Infected! )")
    DefineMap("e3m2","The Vaults of Zin ( Infected! )")
    DefineMap("e3m3","The Tomb of Terror ( Infected! )")
    DefineMap("e3m4","Satan's Dark Delight ( Infected! )")
    DefineMap("e3m5","The Wind Tunnels ( Infected! )")
    DefineMap("e3m6","Chambers of Torment ( Infected! )")
    DefineMap("e3m7","The Haunted Halls ( Infected! )")
    DefineMap("e4m1","The Sewage System ( Infected! )")
    DefineMap("e4m2","The Tower of Despair ( Infected! )")
    DefineMap("e4m3","The Elder God Shrine ( Infected! )")
    DefineMap("e4m4","The Palace of Hate ( Infected! )")
    DefineMap("e4m5","Hell's Atrium ( Infected! )")
    DefineMap("e4m6","The Pain Maze ( Infected! )")
    DefineMap("e4m7","Azure Agony ( Infected! )")
    DefineMap("e4m8","The Nameless City ( Infected! )")
    DefineMap("end","Shub-Niggurath's Pit ( Infected! )")
    DefineMap("start","Introduction ( Infected! )")

	OverrideDefineMap("test/mals_combatbox","Mal's Combatbox")
	OverrideDefineMap("test/test_shadow","Shadow's Arena")
	OverrideDefineMap("test/test_aiming","Box Arena")
	OverrideDefineMap("test/test_obstacles","Obstacle Course")

    #endif

	// Default
	return title;

}