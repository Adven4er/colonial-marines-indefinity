///////////////////////
//BASED TACMAP VALUES//
///////////////////////
/// Converts the overworld x and y to minimap x and y values
#define MINIMAP_PIXEL_FROM_WORLD(val) (val*2-3)
/// actual size of a users screen in pixels
#define SCREEN_PIXEL_SIZE 480
/// tacmaps traits
#define TCMP_MAPS_TRAITS list(ZTRAIT_MARINE_MAIN_SHIP, ZTRAIT_GROUND)

///////////////
//TURF COLORS//
///////////////
#define MINIMAP_SOLID "#ebe5e5ee"
#define MINIMAP_DOOR "#451e5eb8"
#define MINIMAP_FENCE "#8d2294ad"
#define MINIMAP_LAVA "#db4206ad"
#define MINIMAP_DIRT "#9c906dc2"
#define MINIMAP_SNOW "#c4e3e9c7"
#define MINIMAP_MARS_DIRT "#aa5f44cc"
#define MINIMAP_ICE "#93cae0b0"
#define MINIMAP_WATER "#94b0d59c"

//Area colors
#define MINIMAP_AREA_ENGI "#c19504e7"
#define MINIMAP_AREA_ENGI_CAVE "#5a4501e7"
#define MINIMAP_AREA_MEDBAY "#3dbf75ee"
#define MINIMAP_AREA_MEDBAY_CAVE "#17472cee"
#define MINIMAP_AREA_SEC "#a22d2dee"
#define MINIMAP_AREA_SEC_CAVE "#421313ee"
#define MINIMAP_AREA_RESEARCH "#812da2ee"
#define MINIMAP_AREA_RESEARCH_CAVE "#2d1342ee"
#define MINIMAP_AREA_COMMAND "#2d3fa2ee"
#define MINIMAP_AREA_COMMAND_CAVE "#132242ee"
#define MINIMAP_AREA_CAVES "#3f3c3cef"
#define MINIMAP_AREA_JUNGLE "#2b5b2bee"
#define MINIMAP_AREA_COLONY "#6c6767d8"
#define MINIMAP_AREA_LZ "#ebe5e5e3"
#define MINIMAP_AREA_CONTESTED_ZONE "#0603c4ee"

#define MINIMAP_SQUAD_UNKNOWN "#d8d8d8"
#define MINIMAP_SQUAD_ALPHA "#ed1c24"
#define MINIMAP_SQUAD_BRAVO "#fbc70e"
#define MINIMAP_SQUAD_CHARLIE "#76418a"
#define MINIMAP_SQUAD_DELTA "#0c0cae"
#define MINIMAP_SQUAD_ECHO "#00b043"
#define MINIMAP_SQUAD_FOXTROT "#fe7b2e"
#define MINIMAP_SQUAD_SOF "#400000"

#define MINIMAP_ICON_BACKGROUND_CIVILIAN "#7D4820"
#define MINIMAP_ICON_BACKGROUND_CIC "#3f3f3f"
#define MINIMAP_ICON_BACKGROUND_USCM "#888888"
#define MINIMAP_ICON_BACKGROUND_XENO "#3a064d"

#define MINIMAP_ICON_COLOR_COMMANDER "#c6fcfc"
#define MINIMAP_ICON_COLOR_HEAD "#F0C542"
#define MINIMAP_ICON_COLOR_BRONZE "#eb9545"

#define MINIMAP_ICON_COLOR_DOCTOR "#b83737"

//Prison
#define MINIMAP_AREA_CELL_MAX "#570101ee"
#define MINIMAP_AREA_CELL_HIGH "#a54b01ee"
#define MINIMAP_AREA_CELL_MED "#997102e7"
#define MINIMAP_AREA_CELL_LOW "#5a9201ee"
#define MINIMAP_AREA_CELL_VIP "#00857aee"
#define MINIMAP_AREA_SHIP "#885a04e7"


///////////////////
//MOB DATUM FLAGS//
///////////////////
#define TCMP_INVISIBLY_OV			(1<<0)
#define TCMP_INTERACTIVE_MENU		(1<<1)
#define TCMP_ADDITIONAL_OVERLAYS	(1<<2)
#define TCMP_CUSTOM_COLOR			(1<<3)
#define TCMP_VIBISLY_TO_EVRYONE		(1<<4)