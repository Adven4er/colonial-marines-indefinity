//Xenomorph Evolution Code - Colonial Marines - Apophis775 - Last Edit: 11JUN16

//Recoded and consolidated by Abby -- ALL evolutions come from here now. It should work with any caste, anywhere
//All castes need an evolves_to() list in their defines
//Such as evolves_to = list(XENO_CASTE_WARRIOR, XENO_CASTE_SENTINEL, XENO_CASTE_RUNNER, "Badass") etc

/mob/living/carbon/xenomorph/verb/Evolve()
	set name = "Evolve"
	set desc = "Evolve into a higher form."
	set category = "Alien"

	do_evolve()

/mob/living/carbon/xenomorph/proc/do_evolve()
	var/potential_queens = 0

	if(!evolve_checks())
		return

	var/castes_available = caste.evolves_to.Copy()

	for(var/caste in castes_available)
		if(GLOB.xeno_datum_list[caste].minimum_evolve_time > ROUND_TIME)
			castes_available -= caste

	if(!length(castes_available))
		to_chat(src, SPAN_WARNING("The Hive is not capable of supporting any castes you can evolve to yet."))
		return

	var/castepick = tgui_input_list(usr, "You are growing into a beautiful alien! It is time to choose a caste.", "Evolve", castes_available, theme="hive_status")
	if(!castepick) //Changed my mind
		return

	var/datum/caste_datum/caste_datum = GLOB.xeno_datum_list[castepick]
	if(caste_datum && caste_datum.minimum_evolve_time > ROUND_TIME)
		to_chat(src, SPAN_WARNING("The Hive cannot support this caste yet! ([round((caste_datum.minimum_evolve_time - ROUND_TIME) / 10)] seconds remaining)"))
		return

	if(!evolve_checks())
		return

	if((!faction.living_xeno_queen) && castepick != XENO_CASTE_QUEEN && !islarva(src) && !faction.allow_no_queen_actions && !Check_Crash())
		to_chat(src, SPAN_WARNING("The Hive is shaken by the death of the last Queen. You can't find the strength to evolve."))
		return

	if(castepick == XENO_CASTE_QUEEN) //Special case for dealing with queenae
		if(!MODE_HAS_FLAG(MODE_HARDCORE))
			if(SSticker.mode && faction.xeno_queen_timer > world.time)
				to_chat(src, SPAN_WARNING("You must wait about [DisplayTimeText(faction.xeno_queen_timer - world.time, 1, language = CLIENT_LANGUAGE_RUSSIAN)] for the hive to recover from the previous Queen's death."))
				return

			if(plasma_stored >= 500)
				if(faction.living_xeno_queen)
					to_chat(src, SPAN_WARNING("There already is a living Queen."))
					return
			else
				to_chat(src, SPAN_WARNING("You require more plasma! Currently at: [plasma_stored] / 500."))
				return
		else
			to_chat(src, SPAN_WARNING("Nuh-uhh."))
			return
	if(evolution_threshold && castepick != XENO_CASTE_QUEEN) //Does the caste have an evolution timer? Then check it
		if(evolution_stored < evolution_threshold)
			to_chat(src, SPAN_WARNING("You must wait before evolving. Currently at: [evolution_stored] / [evolution_threshold]."))
			return

	// Used for restricting benos to evolve to drone/queen when they're the only potential queen
	for(var/mob/living/carbon/xenomorph/xeno in GLOB.living_xeno_list)
		if(faction != xeno.faction)
			continue

		switch(xeno.tier)
			if(0)
				if(islarva(xeno) && !ispredalienlarva(xeno))
					if(xeno.client && xeno.ckey)
						potential_queens++
				continue
			if(1)
				if(isdrone(xeno))
					if(xeno.client && xeno.ckey)
						potential_queens++

	var/mob/living/carbon/xenomorph/xeno = null

	xeno = SSticker.role_authority.get_caste_by_text(castepick)

	if(isnull(xeno))
		to_chat(usr, SPAN_WARNING("[castepick] is not a valid caste! If you're seeing this message, tell a coder!"))
		return

	if(!can_evolve(castepick, potential_queens))
		return
	to_chat(src, SPAN_XENONOTICE("It looks like the hive can support your evolution to [SPAN_BOLD(castepick)]!"))

	visible_message(SPAN_XENONOTICE("\The [src] begins to twist and contort."), \
	SPAN_XENONOTICE("You begin to twist and contort."))
	xeno_jitter(25)
	evolving = TRUE
	var/level_to_switch_to = get_vision_level()

	if(!do_after(src, 2.5 SECONDS, INTERRUPT_INCAPACITATED, BUSY_ICON_HOSTILE)) // Can evolve while moving
		to_chat(src, SPAN_WARNING("You quiver, but nothing happens. Hold still while evolving."))
		evolving = FALSE
		return

	evolving = FALSE

	if(!isturf(loc)) //qdel'd or moved into something
		return
	if(castepick == XENO_CASTE_QUEEN) //Do another check after the tick.
		if(jobban_isbanned(src, XENO_CASTE_QUEEN))
			to_chat(src, SPAN_WARNING("You are jobbanned from the Queen role."))
			return
		if(faction.living_xeno_queen)
			to_chat(src, SPAN_WARNING("There already is a Queen."))
			return
		if(!faction.allow_queen_evolve)
			to_chat(src, SPAN_WARNING("You can't find the strength to evolve into a Queen"))
			return
	else if(!can_evolve(castepick, potential_queens))
		return

	// subtract the threshold, keep the stored amount
	evolution_stored -= evolution_threshold

	//From there, the new xeno exists, hopefully
	var/mob/living/carbon/xenomorph/new_xeno = new xeno(get_turf(src), src)

	if(!istype(new_xeno))
		//Something went horribly wrong!
		to_chat(usr, SPAN_WARNING("Something went terribly wrong here. Your new xeno is null! Tell a coder immediately!"))
		stack_trace("Xeno evolution failed: [src] attempted to evolve into \'[castepick]\'")
		if(new_xeno)
			qdel(new_xeno)
		return

	switch(new_xeno.tier) //They have evolved, add them to the slot count
		if(2)
			faction.tier_2_xenos |= new_xeno
		if(3)
			faction.tier_3_xenos |= new_xeno

	if(mind)
		mind.transfer_to(new_xeno)
	else
		new_xeno.key = src.key
		if(new_xeno.client)
			new_xeno.client.change_view(world_view_size)

	//Regenerate the new mob's name now that our player is inside
	new_xeno.generate_name()
	if(new_xeno.client)
		new_xeno.set_lighting_alpha(level_to_switch_to)
	if(new_xeno.health - getBruteLoss(src) - getFireLoss(src) > 0) //Cmon, don't kill the new one! Shouldnt be possible though
		new_xeno.bruteloss = src.bruteloss //Transfers the damage over.
		new_xeno.fireloss = src.fireloss //Transfers the damage over.
		new_xeno.updatehealth()

	if(plasma_max == 0)
		new_xeno.plasma_stored = new_xeno.plasma_max
	else
		new_xeno.plasma_stored = new_xeno.plasma_max*(plasma_stored/plasma_max) //preserve the ratio of plasma

	new_xeno.built_structures = built_structures.Copy()

	built_structures = null

	new_xeno.visible_message(SPAN_XENODANGER("A [new_xeno.caste.caste_type] emerges from the husk of \the [src]."), \
	SPAN_XENODANGER(new_xeno.client.auto_lang(LANGUAGE_XENO_EVOLVED)))

	if(faction.living_xeno_queen && faction.living_xeno_queen.observed_xeno == src)
		faction.living_xeno_queen.overwatch(new_xeno)

	src.transfer_observers_to(new_xeno)

	qdel(src)
	new_xeno.xeno_jitter(25)

	if(new_xeno.client)
		new_xeno.client.mouse_pointer_icon = initial(new_xeno.client.mouse_pointer_icon)

	if(new_xeno.mind && SSticker.mode.round_statistics)
		SSticker.mode.round_statistics.track_new_participant(new_xeno.faction, -1) //so an evolved xeno doesn't count as two.
	SSround_recording.recorder.track_player(new_xeno)

/mob/living/carbon/xenomorph/proc/evolve_checks()
	if(!check_state(TRUE))
		return FALSE

	if(is_ventcrawling || !isturf(loc))
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_BP)))
		return FALSE

	if(MODE_HAS_FLAG(MODE_HARDCORE))
		return FALSE

	if(lock_evolve)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_BANISHED)))
		return FALSE

	if(jobban_isbanned(src, JOB_XENOMORPH))//~who so genius to do this is?
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_JB)))
		return FALSE

	if(handcuffed || legcuffed)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_CUF)))
		return FALSE

	if(isnull(caste.evolves_to))
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_EVOLVED_MAX)))
		return FALSE

	if(health < maxHealth)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_HEALTH)))
		return FALSE

	if(agility || fortify || crest_defense)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_POS)))
		return FALSE

	if(world.time < (SSticker.mode.round_time_lobby + XENO_ROUNDSTART_PROGRESS_TIME_2))
		if(caste_type == XENO_CASTE_LARVA || caste_type == XENO_CASTE_PREDALIEN_LARVA)
			var/turf/evoturf = get_turf(src)
			if(!locate(/obj/effect/alien/weeds) in evoturf)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_CANT_EVOLVED_OFFWED)))
				return FALSE

	return TRUE

// The queen de-evo, but on yourself. Only usable once
/mob/living/carbon/xenomorph/verb/Deevolve()
	set name = "De-Evolve"
	set desc = "De-evolve into a lesser form."
	set category = "Alien"

	if(!check_state())
		return

	if(is_ventcrawling || !isturf(loc))
		to_chat(src, SPAN_XENOWARNING(client.auto_lang(LANGUAGE_XENO_CANT_DEEVO)))
		return

	if(health < maxHealth)
		to_chat(src, SPAN_XENOWARNING(client.auto_lang(LANGUAGE_XENO_CANT_DEEVO_TO_WEAK)))
		return

	if(length(caste.deevolves_to) < 1)
		to_chat(src, SPAN_XENOWARNING(client.auto_lang(LANGUAGE_XENO_CANT_DEEVO_TO_LIMIT)))
		return

	if(lock_evolve)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_BANISHED)))
		return FALSE


	var/newcaste

	if(length(caste.deevolves_to) == 1)
		newcaste = caste.deevolves_to[1]
	else if(length(caste.deevolves_to) > 1)
		newcaste = tgui_input_list(src, client.auto_lang(LANGUAGE_XENO_DEEVOLVE_ASK), client.auto_lang(LANGUAGE_XENO_DEEVO), caste.deevolves_to, theme="hive_status")

	if(!newcaste)
		return
	var/alert_msg = replacetext(replacetext(client.auto_lang(LANGUAGE_XENO_DEEVOLVE), "###CASTE_TYPE###", "[caste.caste_type]"), "###NEW_CASTE_TYPE###", "[newcaste]")
	if(alert(src, alert_msg, client.auto_lang(LANGUAGE_CONFIRM), client.auto_lang(LANGUAGE_YES), client.auto_lang(LANGUAGE_NO)) != client.auto_lang(LANGUAGE_YES))
		return

	if(!check_state())
		return

	if(is_ventcrawling)
		return

	if(!isturf(loc))
		return

	if(health <= 0)
		return

	if(lock_evolve)
		to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_XENO_BANISHED)))
		return FALSE

	var/xeno_type
	var/level_to_switch_to = get_vision_level()
	switch(newcaste)
		if("Larva")
			xeno_type = /mob/living/carbon/xenomorph/larva
		if(XENO_CASTE_RUNNER)
			xeno_type = /mob/living/carbon/xenomorph/runner
		if(XENO_CASTE_DRONE)
			xeno_type = /mob/living/carbon/xenomorph/drone
		if(XENO_CASTE_SENTINEL)
			xeno_type = /mob/living/carbon/xenomorph/sentinel
		if(XENO_CASTE_SPITTER)
			xeno_type = /mob/living/carbon/xenomorph/spitter
		if(XENO_CASTE_LURKER)
			xeno_type = /mob/living/carbon/xenomorph/lurker
		if(XENO_CASTE_WARRIOR)
			xeno_type = /mob/living/carbon/xenomorph/warrior
		if(XENO_CASTE_DEFENDER)
			xeno_type = /mob/living/carbon/xenomorph/defender
		if(XENO_CASTE_BURROWER)
			xeno_type = /mob/living/carbon/xenomorph/burrower

	var/mob/living/carbon/xenomorph/new_xeno = new xeno_type(get_turf(src), src)

	new_xeno.built_structures = built_structures.Copy()

	built_structures = null

	if(!istype(new_xeno))
		//Something went horribly wrong!
		to_chat(src, SPAN_WARNING("Something went terribly wrong here. Your new xeno is null! Tell a coder immediately!"))
		if(new_xeno)
			qdel(new_xeno)
		return

	if(mind)
		mind.transfer_to(new_xeno)
	else
		new_xeno.key = key
		if(new_xeno.client)
			new_xeno.client.change_view(world_view_size)
			new_xeno.client.pixel_x = 0
			new_xeno.client.pixel_y = 0

	//Regenerate the new mob's name now that our player is inside
	new_xeno.generate_name()
	if(new_xeno.client)
		new_xeno.set_lighting_alpha(level_to_switch_to)
	new_xeno.visible_message(SPAN_XENODANGER("A [new_xeno.caste.caste_type] emerges from the husk of \the [src]."), \
	SPAN_XENODANGER("You regress into your previous form."))

	if(SSticker.mode.round_statistics && !new_xeno.statistic_exempt)
		SSticker.mode.round_statistics.track_new_participant(faction, -1) //so an evolved xeno doesn't count as two.
	SSround_recording.recorder.track_player(new_xeno)

	src.transfer_observers_to(new_xeno)

	qdel(src)

/mob/living/carbon/xenomorph/proc/can_evolve(castepick, potential_queens)
	var/selected_caste = GLOB.xeno_datum_list[castepick]?.type
	var/free_slots = LAZYACCESS(faction.free_slots, selected_caste)
	if(free_slots)
		return TRUE

	var/burrowed_factor = min(faction.stored_larva, sqrt(4*faction.stored_larva))
	burrowed_factor = round(burrowed_factor)

	var/used_tier_2_slots = length(faction.tier_2_xenos)
	var/used_tier_3_slots = length(faction.tier_3_xenos)
	for(var/caste_path in faction.used_free_slots)
		if(!faction.used_free_slots[caste_path])
			continue
		var/datum/caste_datum/C = caste_path
		switch(initial(C.tier))
			if(2)
				used_tier_2_slots--
			if(3)
				used_tier_3_slots--

	var/totalXenos = burrowed_factor
	for(var/mob/living/carbon/xenomorph/xeno as anything in faction.totalMobs)
		if(xeno.counts_for_slots)
			totalXenos++

	if(tier == 1 && (((used_tier_2_slots + used_tier_3_slots) / totalXenos) * faction.tier_slot_multiplier) >= 0.5 && castepick != XENO_CASTE_QUEEN)
		to_chat(src, SPAN_WARNING("The hive cannot support another Tier 2, wait for either more aliens to be born or someone to die."))
		return FALSE
	else if(tier == 2 && ((used_tier_3_slots / length(faction.totalMobs)) * faction.tier_slot_multiplier) >= 0.20 && castepick != XENO_CASTE_QUEEN)
		to_chat(src, SPAN_WARNING("The hive cannot support another Tier 3, wait for either more aliens to be born or someone to die."))
		return FALSE
	else if(faction.allow_queen_evolve && !faction.living_xeno_queen && potential_queens == 1 && islarva(src) && !Check_Crash() && castepick != XENO_CASTE_DRONE)
		to_chat(src, SPAN_XENONOTICE("The hive currently has no sister able to become Queen! The survival of the hive requires you to be a Drone!"))
		return FALSE

	return TRUE