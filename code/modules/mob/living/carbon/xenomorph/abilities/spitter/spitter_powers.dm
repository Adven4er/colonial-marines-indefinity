/datum/action/xeno_action/onclick/charge_spit/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/xeno = owner

	if(!action_cooldown_check())
		return

	if(!istype(xeno) || !xeno.check_state())
		return

	if(buffs_active)
		to_chat(xeno, SPAN_XENOHIGHDANGER("You cannot stack this!"))
		return

	if(!check_and_use_plasma_owner())
		return

	to_chat(xeno, SPAN_XENOHIGHDANGER("You accumulate acid in your glands. Your next spit will be stronger but shorter-ranged."))
	to_chat(xeno, SPAN_XENOWARNING("Additionally, you are slightly faster and more armored for a small amount of time."))
	xeno.create_custom_empower(icolor = "#93ec78", ialpha = 200, small_xeno = TRUE)
	xeno.balloon_alert(xeno, "your next spit will be stronger", text_color = "#93ec78")
	buffs_active = TRUE
	xeno.ammo = GLOB.ammo_list[/datum/ammo/xeno/acid/spatter] // shitcode is my city
	xeno.speed_modifier -= speed_buff_amount
	xeno.armor_modifier += armor_buff_amount
	xeno.recalculate_speed()

	/// Though the ability's other buffs are supposed to last for its duration, it's only supposed to enhance one spit.
	RegisterSignal(xeno, COMSIG_XENO_POST_SPIT, PROC_REF(disable_spatter))

	addtimer(CALLBACK(src, PROC_REF(remove_effects)), duration)

	apply_cooldown()
	..()
	return

/datum/action/xeno_action/onclick/charge_spit/proc/disable_spatter()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/xeno = owner
	if(xeno.ammo == GLOB.ammo_list[/datum/ammo/xeno/acid/spatter])
		to_chat(xeno, SPAN_XENOWARNING("Your acid glands empty out and return back to normal. You will once more fire long-ranged weak spits."))
		xeno.balloon_alert(xeno, "your spits are back to normal", text_color = "#93ec78")
		xeno.ammo = GLOB.ammo_list[/datum/ammo/xeno/acid] // el codigo de mierda es mi ciudad
	UnregisterSignal(xeno, COMSIG_XENO_POST_SPIT)

/datum/action/xeno_action/onclick/charge_spit/proc/remove_effects()
	var/mob/living/carbon/xenomorph/xeno = owner

	if(!istype(xeno))
		return

	xeno.speed_modifier += speed_buff_amount
	xeno.armor_modifier -= armor_buff_amount
	xeno.recalculate_speed()
	to_chat(xeno, SPAN_XENOHIGHDANGER("You feel your movement speed slow down!"))
	disable_spatter()
	buffs_active = FALSE

/datum/action/xeno_action/activable/tail_stab/spitter/use_ability(atom/A)
	var/target = ..()
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		carbon_target.reagents.add_reagent("molecularacid", 2)
		carbon_target.reagents.set_source_mob(owner, /datum/reagent/toxin/molecular_acid)
