/datum/xeno_mutation/strain/praetorian_dancer
	// My name is Cuban Pete, I'm the King of the Rumba Beat
	name = LANGUAGE_STRAIN_DANCER
	description = LANGUAGE_STRAIN_DESC_DANCER
	flavor_description = LANGUAGE_STRAIN_FLAV_DESC_DANCER
	cost = MUTATOR_COST_EXPENSIVE
	caste_whitelist = list(XENO_CASTE_PRAETORIAN) // Only bae
	mutation_actions_to_remove = list(
		/datum/action/xeno_action/activable/xeno_spit,
		/datum/action/xeno_action/activable/pounce/base_prae_dash,
		/datum/action/xeno_action/activable/prae_acid_ball,
		/datum/action/xeno_action/activable/spray_acid/base_prae_spray_acid,
	)
	mutation_actions_to_add = list(
		/datum/action/xeno_action/activable/prae_impale,
		/datum/action/xeno_action/onclick/prae_dodge,
		/datum/action/xeno_action/activable/prae_tail_trip,
	)
	behavior_delegate_type = /datum/behavior_delegate/praetorian_dancer
	keystone = TRUE

/datum/xeno_mutation/strain/praetorian_dancer/apply_mutator(datum/mutator_set/individual_mutations/mutator_set)
	. = ..()
	if(. == 0)
		return

	var/mob/living/carbon/xenomorph/praetorian/praetorian = mutator_set.xeno
	praetorian.armor_modifier -= XENO_ARMOR_MOD_VERY_SMALL
	praetorian.speed_modifier += XENO_SPEED_FASTMOD_TIER_5
	praetorian.plasma_types = list(PLASMA_CATECHOLAMINE)
	praetorian.claw_type = CLAW_TYPE_SHARP

	mutator_update_actions(praetorian)
	mutator_set.recalculate_actions(description, flavor_description)

	praetorian.recalculate_everything()

	apply_behavior_holder(praetorian)
	praetorian.mutation_icon_state = PRAETORIAN_DANCER
	praetorian.mutation_type = PRAETORIAN_DANCER

/datum/behavior_delegate/praetorian_dancer
	name = "Praetorian Dancer Behavior Delegate"

	var/evasion_buff_amount = 40
	var/evasion_buff_ttl = 25  // 2.5 seconds seems reasonable

	// State
	var/next_slash_buffed = FALSE
	var/slash_evasion_buffed = FALSE
	var/slash_evasion_timer = TIMER_ID_NULL
	var/dodge_activated = FALSE


/datum/behavior_delegate/praetorian_dancer/melee_attack_additional_effects_target(mob/living/carbon/target_carbon)
	if (!isxeno_human(target_carbon))
		return

	if(target_carbon.stat)
		return

	// Clean up all tags to 'refresh' our TTL
	for(var/datum/effects/dancer_tag/target_tag in target_carbon.effects_list)
		qdel(target_tag)

	new /datum/effects/dancer_tag(target_carbon, bound_xeno, , , 35)

	if(ishuman(target_carbon))
		var/mob/living/carbon/human/target_human = target_carbon
		target_human.update_xeno_hostile_hud()
