// Bunker01
// Areas

/area/adminlevel
	ceiling = CEILING_METAL

/area/adminlevel/bunker01
	icon_state = "thunder"
	requires_power = FALSE
	statistic_exempt = TRUE
	flags_area = AREA_NOTUNNEL

/area/adminlevel/bunker01/mainroom
	name = "\improper Bunker Main Room"
	icon_state = "bunker01_main"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/medbay
	name = "\improper Bunker Medbay"
	icon_state = "bunker01_medbay"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/security
	name = "\improper Bunker Security"
	icon_state = "bunker01_security"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/engineering
	name = "\improper Bunker Engineering"
	icon_state = "bunker01_engineering"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/storage
	name = "\improper Bunker Storage"
	icon_state = "bunker01_storage"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/bedroom
	name = "\improper Bunker Bedroom"
	icon_state = "bunker01_bedroom"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/command
	name = "\improper Bunker Command Room"
	icon_state = "bunker01_command"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/bathroom
	name = "\improper Bunker Bathroom"
	icon_state = "bunker01_bathroom"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/kitchen
	name = "\improper Bunker Kitchen"
	icon_state = "bunker01_kitchen"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/hydroponics
	name = "\improper Bunker Hydroponics"
	icon_state = "bunker01_hydroponics"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/breakroom
	name = "\improper Bunker Breakroom"
	icon_state = "bunker01_break"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/gear
	name = "\improper Bunker Gear"
	icon_state = "bunker01_gear"
	ceiling = CEILING_UNDERGROUND_METAL_ALLOW_CAS

/area/adminlevel/bunker01/caves
	name = "\improper Bunker Caves"
	icon_state = "bunker01_caves"
	ceiling = CEILING_UNDERGROUND_ALLOW_CAS
	always_unpowered = TRUE
	requires_power = TRUE

/area/adminlevel/bunker01/caves/outpost
	name = "\improper Bunker Outpost"
	icon_state = "bunker01_caves_outpost"
	ceiling = CEILING_UNDERGROUND_ALLOW_CAS
	requires_power = TRUE
	always_unpowered = FALSE

/area/adminlevel/bunker01/caves/xeno
	name = "\improper Bunker Xeno Hive"
	icon_state = "bunker01_caves_outpost"
	ceiling = CEILING_UNDERGROUND_ALLOW_CAS
	flags_area = AREA_NOTUNNEL|AREA_ALLOW_XENO_JOIN

	var/datum/faction/faction

/area/adminlevel/bunker01/caves/xeno/Initialize()
	. = ..()
	faction = GLOB.faction_datum[FACTION_XENOMORPH_ALPHA]

/area/adminlevel/bunker01/caves/xeno/Entered(atom/movable/arrived, old_loc)
	. = ..()
	if(isxeno(arrived))
		var/mob/living/carbon/xenomorph/xenomorph = arrived

		xenomorph.away_timer = XENO_LEAVE_TIMER
		xenomorph.set_hive_and_update(faction)

// ERT Station
/area/adminlevel/ert_station
	name = "ERT Station"
	icon_state = "erts"
	requires_power = 0
	flags_area = AREA_NOTUNNEL

/area/adminlevel/ert_station/pmc
	name = "PMC Command"
	icon_state = "pmc"

/area/adminlevel/ert_station/uscm
	name = "USCM Command"
	icon_state = "uscm"

/area/adminlevel/ert_station/upp
	name = "UPP Command"
	icon_state = "upp"

/area/adminlevel/ert_station/xeno
	name = "RSC-M Research Facility"
	icon_state = "rsc-m"

//Simulation area
/area/adminlevel/simulation
	name = "Simulated Reality"
	icon_state = "green"
	flags_area = AREA_NOTUNNEL
	requires_power = FALSE

	static_lighting = FALSE
	area_has_base_lighting = TRUE
	luminosity = 1
	base_lighting_alpha = 255


/area/misc/testroom
	requires_power = FALSE
	name = "Test Room"