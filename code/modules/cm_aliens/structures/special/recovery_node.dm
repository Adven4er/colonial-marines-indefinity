//Recovery Node - Heals xenomorphs around it

/obj/effect/alien/resin/special/recovery
	name = XENO_STRUCTURE_RECOVERY
	desc = "A warm, soothing light source that pulsates with a faint hum."
	icon_state = "recovery"
	health = 400
	var/heal_amount = 10
	var/heal_cooldown = 5 SECONDS
	var/last_healed

/obj/effect/alien/resin/special/recovery/get_examine_text(mob/user)
	. = ..()
	if((isxeno(user) || isobserver(user)) && faction)
		. += "Recovers the health of adjacent Xenomorphs."

/obj/effect/alien/resin/special/recovery/process()
	if(last_healed && world.time < last_healed + heal_cooldown)
		return
	var/list/heal_candidates = list()
	for(var/mob/living/carbon/xenomorph/xeno in orange(src, 1))
		if(xeno.health >= xeno.maxHealth || !xeno.resting || xeno.faction != faction)
			continue
		heal_candidates += xeno
	last_healed = world.time
	if(!heal_candidates.len)
		return
	var/mob/living/carbon/xenomorph/picked_candidate = pick(heal_candidates)
	picked_candidate.visible_message(SPAN_HELPFUL("\The [picked_candidate] glows as a warm aura envelops them."), \
				SPAN_HELPFUL("You feel a warm aura envelop you."))
	if(!do_after(picked_candidate, heal_cooldown, INTERRUPT_MOVED, BUSY_ICON_MEDICAL))
		return
	picked_candidate.gain_health(heal_amount)