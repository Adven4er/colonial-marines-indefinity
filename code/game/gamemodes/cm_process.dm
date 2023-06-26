
#define QUEEN_DEATH_COUNTDOWN 10 MINUTES //10 minutes. Can be changed into a variable if it needs to be manipulated later.

#define MODE_INFESTATION_X_MAJOR		"Xenomorph Major Victory"
#define MODE_INFESTATION_M_MAJOR		"Marine Major Victory"
#define MODE_INFESTATION_X_MINOR		"Xenomorph Minor Victory"
#define MODE_INFESTATION_M_MINOR		"Marine Minor Victory"
#define MODE_INFESTATION_DRAW_DEATH		"DRAW: Mutual Annihilation"

#define MODE_WISKEY_OUTPOST_X_MAJOR		"Xenomorph Destroyed Marines"
#define MODE_WISKEY_OUTPOST_M_MAJOR		"Marine Stay Alive"

#define MODE_CRASH_X_MAJOR				"Xenomorph Major Success"
#define MODE_CRASH_M_MAJOR				"Marine Major Success"
#define MODE_CRASH_X_MINOR				"Xenomorph Minor Success"
#define MODE_CRASH_M_MINOR				"Marine Minor Success"

#define CRASH_EVAC_NONE					"CRASH_EVAC_NONE"
#define CRASH_EVAC_INPROGRESS			"CRASH_EVAC_INPROGRESS"
#define CRASH_EVAC_COMPLETED			"CRASH_EVAC_COMPLETED"

#define NUKE_NONE						"NUKE_NONE"
#define NUKE_INPROGRESS					"NUKE_INPROGRESS"
#define NUKE_COMPLETED					"NUKE_COMPLETED"

#define MODE_INFECTION_HUMAN_WIN		"Major Human Victory"
#define MODE_INFECTION_ZOMBIE_WIN		"Major Zombie Victory"

#define MODE_BATTLEFIELD_W_MAJOR		"Wey-Yu PMC Major Success"
#define MODE_BATTLEFIELD_M_MAJOR		"Marine Major Success"
#define MODE_BATTLEFIELD_W_MINOR		"Wey-Yu PMC Minor Success"
#define MODE_BATTLEFIELD_M_MINOR		"Marine Minor Success"
#define MODE_BATTLEFIELD_DRAW_STALEMATE	"DRAW: Stalemate"
#define MODE_BATTLEFIELD_DRAW_DEATH		"DRAW: My Friends Are Dead"

#define MODE_HVH_UPP_WIN				"UPP Victory"
#define MODE_HVH_MARINE_WIN				"Marine Victory"
#define MODE_HVH_WY_WIN					"WY Victory"
#define MODE_HVH_CLF_WIN				"CLF Victory"
#define MODE_HVH_PEACE_CONFERENCE		"Peaceful End"
#define MODE_HVH_NUCLEAR_DESTRUCTION	"Annihilation End"

#define MODE_GENERIC_DRAW_NUKE			"DRAW: Nuclear Explosion"

/*
Like with cm_initialize.dm, these procs exist to quickly populate classic CM game modes.
Specifically for processing, announcing completion, and so on. Simply plug in these procs
in to the appropriate slots, like the in the example game modes, and you're good to go.
This is meant for infestation type game modes for right now (marines vs. aliens, with a chance
of predators), but can be added to include variant game modes (like humans vs. humans).
*/

//If the queen is dead after a period of time, this will end the game.
/datum/game_mode/proc/check_queen_status()
	return

//===================================================\\

				//ANNOUNCE COMPLETION\\

//===================================================\\

/datum/game_mode/proc/declare_completion_announce_fallen_soldiers()
	set waitfor = FALSE
	sleep(2 SECONDS)
	fallen_list += fallen_list_cross
	if(fallen_list.len)
		var/dat = "<br>"
		dat += SPAN_ROUNDBODY("На поля сражения...<br>")
		dat += SPAN_CENTERBOLD("В память о наших погибших солдатах: <br>")
		for(var/i = 1 to fallen_list.len)
			if(i != fallen_list.len)
				dat += "[fallen_list[i]], "
			else
				dat += "[fallen_list[i]].<br>"
		to_world("[dat]")


/datum/game_mode/proc/declare_completion_announce_xenomorphs()
	set waitfor = FALSE
	sleep(2 SECONDS)
	if(length(xenomorphs) || length(dead_queens))
		var/dat = "<br>"
		dat += SPAN_ROUNDBODY("<br>The xenomorph Queen(s) were:")
		var/mob/mob
		for (var/msg in dead_queens)
			dat += msg
		for(var/datum/mind/X in xenomorphs)
			if(!istype(X))
				continue

			mob = X.current
			if(!mob || !mob.loc)
				mob = X.original
			if(mob && mob.loc && isqueen(mob) && mob.stat != DEAD) // Dead queens handled separately
				dat += "<br>[X.key] was [mob] [SPAN_BOLDNOTICE("(SURVIVED)")]"

		to_world("[dat]")

/datum/game_mode/proc/declare_completion_announce_predators()
	set waitfor = FALSE
	sleep(2 SECONDS)
	if(length(predators))
		var/dat = "<br>"
		dat += SPAN_ROUNDBODY("<br>The Predators were:")
		for(var/entry in predators)
			dat += "<br>[entry] was [predators[entry]["Name"]] [SPAN_BOLDNOTICE("([predators[entry]["Status"]])")]"
		to_world("[dat]")


/datum/game_mode/proc/declare_completion_announce_medal_awards()
	set waitfor = FALSE
	sleep(2 SECONDS)
	if(GLOB.medal_awards.len)
		var/dat = "<br>"
		dat +=  SPAN_ROUNDBODY("<br>Приставлены к Награде:")
		for(var/recipient in GLOB.medal_awards)
			var/datum/recipient_awards/recipient_award = GLOB.medal_awards[recipient]
			for(var/i in 1 to recipient_award.medal_names.len)
				dat += "<br><b>[recipient_award.recipient_rank] [recipient]</b> is awarded [recipient_award.posthumous[i] ? "posthumously " : ""]the <span class='boldnotice'>[recipient_award.medal_names[i]]</span>: \'<i>[recipient_award.medal_citations[i]]</i>\'."
		to_world(dat)
	if(GLOB.jelly_awards.len)
		var/dat = "<br>"
		dat +=  SPAN_ROUNDBODY("<br>Royal Jelly Awards:")
		for(var/recipient in GLOB.jelly_awards)
			var/datum/recipient_awards/recipient_award = GLOB.jelly_awards[recipient]
			for(var/i in 1 to recipient_award.medal_names.len)
				dat += "<br><b>[recipient]</b> is awarded [recipient_award.posthumous[i] ? "posthumously " : ""]a <span class='boldnotice'>[recipient_award.medal_names[i]]</span>: \'<i>[recipient_award.medal_citations[i]]</i>\'[recipient_award.giver_rank[i] ? " by [recipient_award.giver_rank[i]]" : ""][recipient_award.giver_name[i] ? " ([recipient_award.giver_name[i]])" : ""]."
		to_world(dat)

/datum/game_mode/proc/declare_fun_facts()
	set waitfor = FALSE
	sleep(2 SECONDS)
	to_chat_spaced(world, margin_bottom = 0, html = SPAN_ROLE_BODY("|______________________|"))
	to_world(SPAN_ROLE_HEADER("FUN FACTS"))
	var/list/fact_types = subtypesof(/datum/random_fact)
	for(var/fact_type as anything in fact_types)
		var/datum/random_fact/fact_human = new fact_type(set_check_human = TRUE, set_check_xeno = FALSE)
		fact_human.announce()
	for(var/fact_type as anything in fact_types)
		var/datum/random_fact/fact_xeno = new fact_type(set_check_human = FALSE, set_check_xeno = TRUE)
		fact_xeno.announce()
	to_chat_spaced(world, margin_top = 0, html = SPAN_ROLE_BODY("|______________________|"))

//===================================================\\

					//HELPER PROCS\\

//===================================================\\

//Spawns a larva in an appropriate location
/datum/game_mode/proc/spawn_latejoin_larva()
	var/mob/living/carbon/xenomorph/larva/new_xeno = new /mob/living/carbon/xenomorph/larva(get_turf(pick(GLOB.xeno_spawns)))
	new_xeno.visible_message(SPAN_XENODANGER("A larva suddenly burrows out of the ground!"),
	SPAN_XENODANGER("You burrow out of the ground and awaken from your slumber. For the Hive!"))
	new_xeno << sound('sound/effects/xeno_newlarva.ogg')

// Open podlocks with the given ID if they aren't already opened.
// DO NOT USE THIS WITH ID's CORRESPONDING TO SHUTTLES OR THEY WILL BREAK!
/datum/game_mode/proc/open_podlocks(podlock_id)
	for(var/obj/structure/machinery/door/poddoor/mob in machines)
		if(mob.id == podlock_id && mob.density)
			mob.open()

// Variables for the below function that we need to keep throught the round
GLOBAL_VAR_INIT(peak_humans, 1)
GLOBAL_VAR_INIT(peak_xenos, 1)

// 30 minutes in (we will add to that!)
GLOBAL_VAR_INIT(last_xeno_bioscan, 30 MINUTES)
// 30 minutes in (we will add to that!)
GLOBAL_VAR_INIT(last_human_bioscan, 30 MINUTES)
// 5 minutes in
GLOBAL_VAR_INIT(next_predator_bioscan, 5 MINUTES)
// 30 minutes in
GLOBAL_VAR_INIT(next_admin_bioscan, 30 MINUTES)

/datum/game_mode/proc/select_lz(obj/structure/machinery/computer/shuttle/dropship/flight/console)
	if(active_lz)
		return
	active_lz = console
	if(SSevacuation.ship_operation_stage_status < OPERATION_FIRST_LANDING)
		SSevacuation.ship_operation_stage_status = OPERATION_FIRST_LANDING
	// The announcement to all Humans.
	var/name = "[MAIN_AI_SYSTEM] Стадия Операции"
	var/input = "Командный ордер.\n\n[active_lz.loc.loc] определена как главная зона высадки."
	faction_announcement(input, name)

/datum/game_mode/proc/announce_bioscans()
	//Depending on how either side is doing, we speed up the bioscans
	//Formula is - last bioscan time, plus 30 minutes multiplied by ratio of current pop divided by highest pop
	//So if you have peak 30 xenos, if you still have 30 xenos, humans will have to wait 30 minutes between bioscans
	//But if you fall down to 15 xenos, humans will get them every 15 minutes
	//But never more often than 5 minutes apart
	var/nextXenoBioscan = GLOB.last_xeno_bioscan + max(30 MINUTES * length(GLOB.alive_human_list) / GLOB.peak_humans, 5 MINUTES)
	var/nextHumanBioscan = GLOB.last_human_bioscan + max(30 MINUTES * length(GLOB.living_xeno_list) / GLOB.peak_xenos, 5 MINUTES)
	GLOB.bioscan_data.get_scan_data()
	if(world.time > GLOB.next_predator_bioscan)
		GLOB.bioscan_data.yautja_bioscan()//Also does ghosts
		GLOB.next_predator_bioscan += 5 MINUTES//5 minutes, straight

	if(world.time > nextXenoBioscan)
		GLOB.last_xeno_bioscan = world.time
		GLOB.bioscan_data.qm_bioscan()

	if(world.time > nextHumanBioscan)
		GLOB.last_human_bioscan = world.time
		GLOB.bioscan_data.ares_bioscan(FALSE)


/datum/game_mode/proc/count_xenos(list/z_levels = SSmapping.levels_by_any_trait(list(ZTRAIT_GROUND, ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP)))
	var/num_xenos = 0
	for(var/i in GLOB.living_xeno_list)
		var/mob/mob = i
		if(mob.z && (mob.z in z_levels) && !istype(mob.loc, /turf/open/space)) //If they have a z var, they are on a turf.
			num_xenos++
	return num_xenos

/datum/game_mode/proc/count_humans_and_xenos(list/z_levels = SSmapping.levels_by_any_trait(list(ZTRAIT_GROUND, ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP)))
	var/num_humans = 0
	var/num_xenos = 0

	for(var/mob/mob in GLOB.player_list)
		if(mob.z && (mob.z in z_levels) && mob.stat != DEAD && !istype(mob.loc, /turf/open/space)) //If they have a z var, they are on a turf.
			if(ishuman(mob) && !isyautja(mob) && !(mob.status_flags & XENO_HOST) && !iszombie(mob))
				var/mob/living/carbon/human/human = mob
				if(((human.species && human.species.name == "Human") || (human.is_important)) && human.faction) //only real humans count, or those we have set to also be included
					num_humans++
			else
				var/area/area = get_area(mob)
				if(isxeno(mob))
					var/mob/living/carbon/xenomorph/xeno = mob
					if(!xeno.counts_for_roundend)
						continue
					if(!xeno.faction || (xeno.faction.need_round_end_check && !xeno.faction.can_delay_round_end(xeno)))
						continue
					if(!xeno.faction || (xeno.faction.need_round_end_check && !xeno.faction.can_delay_round_end(xeno)) || area.flags_area & AREA_AVOID_BIOSCAN)
						continue
					num_xenos++
				else if(iszombie(mob))
					if(area.flags_area & AREA_AVOID_BIOSCAN)
						continue
					num_xenos++

	return list(num_humans,num_xenos)

/datum/game_mode/proc/count_marines_and_pmcs(list/z_levels = SSmapping.levels_by_any_trait(list(ZTRAIT_GROUND, ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP)))
	var/num_marines = 0
	var/num_pmcs = 0

	for(var/i in GLOB.alive_human_list)
		var/mob/mob = i
		if(mob.z && (mob.z in z_levels) && !istype(mob.loc, /turf/open/space))
			if(mob.faction.faction_name in FACTION_LIST_WY)
				num_pmcs++
			else if(mob.faction.faction_name == FACTION_MARINE)
				num_marines++

	return list(num_marines,num_pmcs)

/datum/game_mode/proc/count_marines(list/z_levels = SSmapping.levels_by_any_trait(list(ZTRAIT_GROUND, ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP)))
	var/num_marines = 0

	for(var/i in GLOB.alive_human_list)
		var/mob/mob = i
		if(mob.z && (mob.z in z_levels) && !istype(mob.loc, /turf/open/space))
			if(mob.faction.faction_name == FACTION_MARINE)
				num_marines++

	return num_marines


/*
#undef QUEEN_DEATH_COUNTDOWN
#undef MODE_INFESTATION_X_MAJOR
#undef MODE_INFESTATION_M_MAJOR
#undef MODE_INFESTATION_X_MINOR
#undef MODE_INFESTATION_M_MINOR
#undef MODE_INFESTATION_DRAW_DEATH
#undef MODE_BATTLEFIELD_W_MAJOR
#undef MODE_BATTLEFIELD_M_MAJOR
#undef MODE_BATTLEFIELD_W_MINOR
#undef MODE_BATTLEFIELD_M_MINOR
#undef MODE_BATTLEFIELD_DRAW_STALEMATE
#undef MODE_BATTLEFIELD_DRAW_DEATH
#undef MODE_GENERIC_DRAW_NUKE*/