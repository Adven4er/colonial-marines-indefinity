/mob/living
	see_invisible = SEE_INVISIBLE_LIVING

	//Health and life related vars
	var/maxHealth = 100 //Maximum health that should be possible.
	var/health = 100 //A mob's health

	//Damage related vars, NOTE: THESE SHOULD ONLY BE MODIFIED BY PROCS
	var/bruteloss = 0 //Brutal damage caused by brute force (punching, being clubbed by a toolbox ect... this also accounts for pressure damage)
	var/oxyloss = 0 //Oxygen depravation damage (no air in lungs)
	var/toxloss = 0 //Toxic damage caused by being poisoned or radiated
	var/fireloss = 0 //Burn damage caused by being way too hot, too cold or burnt.
	var/cloneloss = 0 //Damage caused by being cloned or ejected from the cloner early
	var/brainloss = 0 //'Retardation' damage caused by someone hitting you in the head with a bible or being infected with brainrot.
	var/halloss = 0 //Hallucination damage. 'Fake' damage obtained through hallucinating or the holodeck. Sleeping should cause it to wear off.

	var/hallucination = 0 //Directly affects how long a mob will hallucinate for
	var/list/atom/hallucinations = list() //A list of hallucinated people that try to attack the mob. See /obj/effect/fake_attacker in hallucinations.dm

	var/last_special = 0 //Used by the resist verb, likely used to prevent players from bypassing next_move by logging in/out.

	var/now_pushing = null

	var/cameraFollow = null

	var/tod = null // Time of death

	var/silent = null //Can't talk. Value goes down every life proc.

	var/fire_luminosity

	// Putting these here for attack_animal().
	var/melee_damage_lower = 0
	var/melee_damage_upper = 0
	var/attacktext = "attacks"
	var/attack_sound = null
	/// Custom sound if the mob gets slashed by a xenomorph
	var/custom_slashed_sound
	var/friendly = "nuzzles"
	var/wall_smash = 0

	//Emotes
	var/recent_audio_emote = FALSE

	var/on_fire = FALSE //The "Are we on fire?" var
	var/fire_stacks = 0 //Tracks how many stacks of fire we have on, max is
	var/datum/reagent/fire_reagent

	var/is_being_hugged = 0 //Is there a hugger humping our face?
	var/chestburst = 0 // 0: normal, 1: bursting, 2: bursted.
	var/first_xeno = FALSE //Are they the first wave of infected?
	var/in_stasis = FALSE //Is the mob in stasis bag?

	var/list/icon/pipes_shown = list()
	var/last_played_vent

	var/pull_speed = 0 //How much slower or faster this mob drags as a base

	var/image/attack_icon = null //the image used as overlay on the things we attack.

	COOLDOWN_DECLARE(zoom_cooldown) //Cooldown on using zooming items, to limit spam

	var/do_bump_delay = 0 // Flag to tell us to delay movement because of being bumped

	var/reagent_move_delay_modifier = 0 //negative values increase movement speed

	light_system = MOVABLE_LIGHT

	var/blood_type = "X*"

	//Flags for any active emotes the mob may be performing
	var/flags_emote = NO_FLAGS
	//ventcrawl
	var/list/canEnterVentWith = list(
		/obj/item/implant,
		/obj/item/clothing/mask/facehugger,
		/obj/item/device/radio,
		/obj/structure/machinery/camera,
		/obj/limb,
		/obj/item/alien_embryo
	)
	//blood.dm
	///How much blood the mob has
	var/blood_volume = 0
	///How much blood the mob should ideally have
	var/max_blood = BLOOD_VOLUME_NORMAL
	///How much blood the mob can have
	var/limit_blood = BLOOD_VOLUME_MAXIMUM

	var/datum/pain/pain //Pain datum for the mob, set on New()
	var/datum/stamina/stamina

	var/action_delay //for do_after

	//Surgery vars.
	///Assoc. list - the operations being performed, by aim zone. Both boolean and link to that surgery.
	var/list/active_surgeries = DEFENSE_ZONES_LIVING
	///Assoc. list - incision depths, by aim zone. Set by initialize_incision_depths().
	var/list/incision_depths = DEFENSE_ZONES_LIVING

	var/current_weather_effect_type

	var/atom/movable/icon_cutter

	/// FOV view that is applied from either nativeness or traits
//	var/fov_view
	/// Native FOV that will be applied if a config is enabled
//	var/native_fov = FOV_90_DEGREES
	/// Lazy list of FOV traits that will apply a FOV view when handled.
//	var/list/fov_traits

	var/slash_verb = "attack"
	var/slashes_verb = "attacks"

	///what icon the mob uses for speechbubbles
	var/bubble_icon = "default"
	var/bubble_icon_x_offset = 0
	var/bubble_icon_y_offset = 0

	/// This is what the value is changed to when the mob dies. Actual BMV definition in atom/movable.
	var/dead_black_market_value = 0