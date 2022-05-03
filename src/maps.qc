#define ShowModName 1
#define ModName "Infected"


#define FirstDefineMap(_bspname,_maptitle) if(mapname == ##_bspname && title == ##_maptitle) { return ##_maptitle" ("ModName")"; }
#define DefineMap(_bspname,_maptitle) else FirstDefineMap(_bspname,_maptitle)
#define OverrideDefineMap(_bspname,_maptitle) else if(mapname == ##_bspname) { return ##_maptitle" ("ModName")"; }

string(string title) GetMapName =
{
    if(mapname == "dm1") {
        return "DM1 (INFECTED)";
    }
    else if(mapname == "dm2") {
        return "DM2 (INFECTED)";
    }
    else if(mapname == "dm3") {
        return "DM3 (INFECTED)";
    }
    else if(mapname == "dm4") {
        return "DM4 (INFECTED)";
    }
    else if(mapname == "dm5") {
        return "DM5 (INFECTED)";
    }
    else if(mapname == "dm6") {
        return "DM6 (INFECTED)";
    }
    else if(mapname == "dm7") {
        return "DM7 (INFECTED)";
    }
    else if(mapname == "dm8") {
        return "DM8 (INFECTED)";
    }
    return "(INFECTED)";
}