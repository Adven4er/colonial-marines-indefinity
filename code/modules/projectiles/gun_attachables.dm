//Gun attachable items code. Lets you add various effects to firearms.
//Some attachables are hardcoded in the projectile firing system, like grenade launchers, flamethrowers.
/*
When you are adding new guns into the attachment list, or even old guns, make sure that said guns
properly accept overlays. You can find the proper offsets in the individual gun dms, so make sure
you set them right. It's a pain to go back to find which guns are set incorrectly.
To summarize: rail attachments should go on top of the rail. For rifles, this usually means the middle of the gun.
For handguns, this is usually toward the back of the gun. SMGs usually follow rifles.
Muzzle attachments should connect to the barrel, not sit under or above it. The only exception is the bayonet.
Underrail attachments should just fit snugly, that's about it. Stocks are pretty obvious.

All attachment offsets are now in a list, including stocks. Guns that don't take attachments can keep the list null.
~N

Defined in conflicts.dm of the #defines folder.
#define ATTACH_REMOVABLE 1
#define ATTACH_ACTIVATION 2
#define ATTACH_PROJECTILE 4
#define ATTACH_RELOADABLE 8
#define ATTACH_WEAPON 16
*/

/obj/item/attachable
	name = "attachable item"
	desc = "It's the very theoretical concept of an attachment. You should never see this."
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = null
	item_state = null
	var/attach_icon //the sprite to show when the attachment is attached when we want it different from the icon_state.
	var/pixel_shift_x = 16 //Determines the amount of pixels to move the icon state for the overlay.
	var/pixel_shift_y = 16 //Uses the bottom left corner of the item.

	flags_atom =  FPRINT|CONDUCT
	matter = list("metal" = 2000)
	w_class = SIZE_SMALL
	force = 1
	var/slot = null //"muzzle", "rail", "under", "stock", "special"

	light_system = MOVABLE_LIGHT

	/*
	Anything that isn't used as the gun fires should be a flat number, never a percentange. It screws with the calculations,
	and can mean that the order you attach something/detach something will matter in the final number. It's also completely
	inaccurate. Don't worry if force is ever negative, it won't runtime.
	*/
	//These bonuses are applied only as the gun fires a projectile.

	//These are flat bonuses applied and are passive, though they may be applied at different points.
	var/accuracy_mod = 0 //Modifier to firing accuracy, works off a multiplier.
	var/accuracy_unwielded_mod = 0 //same as above but for onehanded.
	var/damage_mod = 0 //Modifer to the damage mult, works off a multiplier.
	var/damage_falloff_mod = 0 //Modifier to damage falloff, works off a multiplier.
	var/damage_buildup_mod = 0 //Modifier to damage buildup, works off a multiplier.
	var/range_min_mod = 0 //Modifier to minimum effective range, tile value.
	var/range_max_mod = 0 //Modifier to maximum effective range, tile value.
	var/melee_mod = 0 //Changing to a flat number so this actually doesn't screw up the calculations.
	var/scatter_mod = 0 //Increases or decreases scatter chance.
	var/scatter_unwielded_mod = 0 //same as above but for onehanded firing.
	var/recoil_mod = 0 //If positive, adds recoil, if negative, lowers it. Recoil can't go below 0.
	var/recoil_unwielded_mod = 0 //same as above but for onehanded firing.
	var/burst_scatter_mod = 0 //Modifier to scatter from wielded burst fire, works off a multiplier.
	var/light_mod = 0 //Adds an x-brightness flashlight to the weapon, which can be toggled on and off.
	var/delay_mod = 0 //Changes firing delay. Cannot go below 0.
	var/burst_mod = 0 //Changes burst rate. 1 == 0.
	var/size_mod = 0 //Increases the weight class.
	var/aim_speed_mod = 0 //Changes the aiming speed slowdown of the wearer by this value.
	var/wield_delay_mod = 0 //How long ADS takes (time before firing)
	var/movement_onehanded_acc_penalty_mod = 0 //Modifies accuracy/scatter penalty when firing onehanded while moving.
	var/velocity_mod = 0 // Added velocity to bullets
	var/hud_offset_mod  = 0 //How many pixels to adjust the gun's sprite coords by. Ideally, this should keep the gun approximately centered.

	var/activation_sound = 'sound/weapons/handling/gun_underbarrel_activate.ogg'
	var/deactivation_sound = 'sound/weapons/handling/gun_underbarrel_deactivate.ogg'

	var/flags_attach_features = ATTACH_REMOVABLE

	var/obj/item/projectile/current_rounds[] //How much it has.
	var/max_rounds = 0 //How much ammo it can store
	var/ammo_position = 0
	var/spawn_empty = TRUE
	var/default_projectile = /obj/item/projectile
	var/datum/ammo/ammo = null //If it has a default bullet-like ammo.
	var/force_ammo = FALSE
	var/caliber = null

	var/attachment_action_type

	var/hidden = FALSE //Render on gun?


	//gun healths
	var/max_durability = WEAPON_DURABILITY_MEDIUM
	var/durability = 0
	var/durability_tier = WEAPON_DAMAGE_MEDIUM
	var/durability_percentage
	var/drowned = 0
	var/broken = FALSE
	var/drown_resist = FALSE
	//oiling
	var/oil = 0
	var/oil_max = 100
	//failure
	var/req_fix = FALSE
	var/failure_probability = WEAPON_FAILURE_SMALL
	var/can_jammed = TRUE
	var/cause_attach_failure = "осечки подствольника"
	//overlay
	var/image/damage_overlay
	var/image/dirty
	var/image/drown


	/// An assoc list in the format list(/datum/element/bullet_trait_to_give = list(...args))
	/// that will be given to a projectile with the current ammo datum
	var/list/list/traits_to_give
	/// List of traits to be given to the gun itself.
	var/list/gun_traits

/obj/item/attachable/Initialize(mapload, ...)
	. = ..()
	set_bullet_traits()
	durability = max_durability
	durability_percentage()
	oil(oil_max)
	if(ammo)
		ammo = GLOB.ammo_list[ammo]
	if(max_rounds && (ammo || spawn_empty))
		generate_ammo()

/obj/item/attachable/Destroy()
	ammo = null
	. = ..()

/obj/item/attachable/proc/generate_ammo()
	current_rounds = list()
	current_rounds.len = max_rounds
	for(var/i = 1 to max_rounds)
		current_rounds[i] = spawn_empty ? "empty" : new default_projectile(src, null, ammo, caliber)
	if(!spawn_empty)
		ammo_position = current_rounds.len //The position is always in the beginning [1]. It can move from there.

/obj/item/attachable/proc/set_bullet_traits()
	return

/obj/item/attachable/attackby(obj/item/I, mob/user)
	if(flags_attach_features & ATTACH_RELOADABLE)
		if(user.get_inactive_hand() != src)
			to_chat(user, SPAN_WARNING("You have to hold [src] to do that!"))
		else
			reload_attachment(I, user)
		return TRUE
	else
		. = ..()

/obj/item/attachable/proc/oil(oil_al, failure_ap = 0)
	oil += oil_al
	failure_probability -= failure_probability * failure_ap

/obj/item/attachable/proc/handle_damage(force = FALSE) //handle chance do break gan or damage
	if(broken)
		return
	if(durability < 1)
		broken = 1
		cell_explosion(src, 40, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data(cause_attach_failure))
	if(oil && !prob(0.01) && !drowned || !prob(failure_probability) || force)
		if(oil)
			durability -= (rand(0,500)/500) * durability_tier * (drowned * 10)
		else
			durability -= (rand(0,1000)/1000) * durability_tier * (drowned * 10)
			failure_probability += (rand(0,1000)/1000) * durability_tier * (drowned * 10)
	else
		return FALSE
	durability_percentage()
	update_icon()
	return TRUE

/obj/item/attachable/proc/durability_percentage()
	durability_percentage = CEILING((durability * 100) / (max_durability), 1) + rand(-2,2)
	if(durability_percentage > 100)
		durability_percentage = 100
	else if(durability_percentage < 0)
		durability_percentage = 0

/obj/item/attachable/proc/update_damage_overlay()
	if(durability <= max_durability)
		var/icon/I = new /icon('icons/obj/items/weapons/guns/effect.dmi', "gun_damage")
		damage_overlay = image(I)
		damage_overlay.alpha = 255 * (1 - (durability / max_durability))
		damage_overlay.blend_mode = BLEND_INSET_OVERLAY
		overlays += damage_overlay
	if(!oil)
		var/icon/I = new /icon('icons/obj/items/weapons/guns/effect.dmi', "dirty")
		dirty = image(I)
		dirty.blend_mode = BLEND_INSET_OVERLAY
		overlays += dirty
	if(drowned)
		var/icon/I = new /icon('icons/obj/items/weapons/guns/effect.dmi', "drowned")
		drown = image(I)
		drown.blend_mode = BLEND_INSET_OVERLAY
		overlays += drown

/obj/item/attachable/update_icon()
	if(overlays)
		overlays.Cut()
	else
		overlays = list()
	..()

	update_damage_overlay()

/obj/item/attachable/proc/can_be_attached_to_gun(mob/user, obj/item/weapon/gun/gun)
	if(gun.attachable_allowed && !(type in gun.attachable_allowed) )
		to_chat(user, SPAN_WARNING("[src] doesn't fit on [gun]!"))
		return FALSE
	return TRUE

/obj/item/attachable/proc/Attach(obj/item/weapon/gun/gun)
	if(!istype(gun)) return //Guns only

	/*
	This does not check if the attachment can be removed.
	Instead of checking individual attachments, I simply removed
	the specific guns for the specific attachments so you can't
	attempt the process in the first place if a slot can't be
	removed on a gun. can_be_removed is instead used when they
	try to strip the gun.
	*/
	if(gun.attachments[slot])
		var/obj/item/attachable/A = gun.attachments[slot]
		A.Detach(null, gun)

	if(ishuman(loc))
		var/mob/living/carbon/human/M = src.loc
		M.drop_held_item(src)
	forceMove(gun)

	gun.attachments[slot] = src
	gun.recalculate_attachment_bonuses()

	if(gun.burst_amount <= 1)
		gun.flags_gun_features &= ~GUN_BURST_ON //Remove burst if they can no longer use it.
	gun.update_force_list() //This updates the gun to use proper force verbs.

	var/mob/living/living
	if(isliving(gun.loc))
		living = gun.loc

	if(attachment_action_type)
		var/given_action = FALSE
		if(living && (gun == living.l_hand || gun == living.r_hand))
			give_action(living, attachment_action_type, src, gun)
			given_action = TRUE
		if(!given_action)
			new attachment_action_type(src, gun)

	// Sharp attachments (bayonet) make weapons sharp as well.
	if(sharp)
		gun.sharp = sharp

	for(var/trait in gun_traits)
		ADD_TRAIT(gun, trait, TRAIT_SOURCE_ATTACHMENT(slot))
	for(var/entry in traits_to_give)
		if(!gun.in_chamber)
			break
		var/list/L
		// Check if this is an ID'd bullet trait
		if(istext(entry))
			L = traits_to_give[entry].Copy()
		else
			// Prepend the bullet trait to the list
			L = list(entry) + traits_to_give[entry]
		// Apply bullet traits from attachment to gun's current projectile
		gun.in_chamber.apply_bullet_trait(L)

/obj/item/attachable/proc/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	if(!istype(detaching_gub)) return //Guns only

	detaching_gub.on_detach(user)

	if(flags_attach_features & ATTACH_ACTIVATION)
		activate_attachment(detaching_gub, null, TRUE)

	detaching_gub.attachments[slot] = null
	detaching_gub.recalculate_attachment_bonuses()

	for(var/X in detaching_gub.actions)
		var/datum/action/DA = X
		if(DA.target == src)
			qdel(X)
			break

	forceMove(get_turf(detaching_gub))

	if(sharp)
		detaching_gub.sharp = 0

	for(var/trait in gun_traits)
		REMOVE_TRAIT(detaching_gub, trait, TRAIT_SOURCE_ATTACHMENT(slot))
	for(var/entry in traits_to_give)
		if(!detaching_gub.in_chamber)
			break
		var/list/L
		if(istext(entry))
			L = traits_to_give[entry].Copy()
		else
			L = list(entry) + traits_to_give[entry]
		// Remove bullet traits of attachment from gun's current projectile
		detaching_gub.in_chamber._RemoveElement(L)

/obj/item/attachable/ui_action_click(mob/living/user, obj/item/weapon/gun/gun)
	activate_attachment(gun, user)
	return //success

/obj/item/attachable/proc/activate_attachment(atom/target, mob/user) //This is for activating stuff like flamethrowers, or switching weapon modes.
	return

/obj/item/attachable/proc/reload_attachment(obj/item/I, mob/user)
	return

/obj/item/attachable/proc/unique_action(mob/user)
	return

///Returns TRUE if its functionality is successfully used, FALSE if gun's own unloading should proceed instead.
/obj/item/attachable/proc/unload_attachment(mob/user, reload_override = 0, drop_override = 0, loc_override = 0)
	return FALSE

/obj/item/attachable/proc/fire_attachment(atom/target, obj/item/weapon/gun/gun, mob/user) //For actually shooting those guns.
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN_ATTACHMENT, src) // Because of this, the . = ..() check should be called last, just before firing
	return TRUE

/obj/item/attachable/proc/handle_attachment_description()
	var/base_attachment_desc
	switch(slot)
		if("rail")
			base_attachment_desc = "It has a [icon2html(src)] [name] mounted on the top."
		if("muzzle")
			base_attachment_desc = "It has a [icon2html(src)] [name] mounted on the front."
		if("stock")
			base_attachment_desc = "It has a [icon2html(src)] [name] for a stock."
		if("under")
			var/output = "It has a [icon2html(src)] [name]"
			if(flags_attach_features & ATTACH_WEAPON)
				output += " ([ammo_position]/[max_rounds])"
			output += " mounted underneath.<br>"
			base_attachment_desc = output
		else
			base_attachment_desc = "It has a [icon2html(src)] [name] attached."
	return handle_pre_break_attachment_description(base_attachment_desc) + "<br>"

/obj/item/attachable/proc/handle_pre_break_attachment_description(base_description_text as text)
	return base_description_text

// ======== Muzzle Attachments ======== //

/obj/item/attachable/suppressor
	name = "suppressor"
	desc = "A small tube with exhaust ports to expel noise and gas.\n Does not completely silence a weapon, but does make it much quieter and a little more accurate and stable at the cost of slightly reduced damage."
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "suppressor"
	slot = "muzzle"
	pixel_shift_y = 15
	attach_icon = "suppressor_a"
	hud_offset_mod = -3
	gun_traits = list(TRAIT_GUN_SILENCED)

/obj/item/attachable/suppressor/New()
	..()
	damage_falloff_mod = 0.1
	attach_icon = pick("suppressor_a","suppressor2_a")

/obj/item/attachable/suppressor/xm40_integral
	name = "XM40 integral suppressor"
	icon_state = "m40sd_suppressor"
	attach_icon = "m40sd_suppressor_a"

/obj/item/attachable/suppressor/xm40_integral/New()
	..()
	attach_icon = "m40sd_suppressor_a"

/obj/item/attachable/bayonet
	name = "M5 'Night Raider' bayonet"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "bayonet"
	item_state = "combat_knife"
	desc = "The standard-issue bayonet of the Colonial Marines. You can slide this knife into your boots, or attach it to the end of a rifle."
	sharp = IS_SHARP_ITEM_ACCURATE
	force = MELEE_FORCE_NORMAL
	throwforce = MELEE_FORCE_NORMAL
	throw_speed = SPEED_VERY_FAST
	throw_range = 6
	hitsound = 'sound/weapons/slash.ogg'
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	attack_speed = 9
	flags_equip_slot = SLOT_FACE
	flags_armor_protection = SLOT_FACE
	flags_item = CAN_DIG_SHRAPNEL

	attach_icon = "bayonet_a"
	melee_mod = 20
	slot = "muzzle"
	pixel_shift_x = 14 //Below the muzzle.
	pixel_shift_y = 18
	hud_offset_mod = -4
	var/pry_delay = 3 SECONDS

/obj/item/attachable/bayonet/Initialize(mapload, ...)
	. = ..()
	if(flags_equip_slot & SLOT_FACE)
		AddElement(/datum/element/mouth_drop_item)

/obj/item/attachable/bayonet/New()
	..()
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_1

/obj/item/attachable/bayonet/upp_replica
	name = "Type 80 bayonet"
	icon_state = "upp_bayonet"
	item_state = "combat_knife"
	attach_icon = "upp_bayonet_a"
	desc = "The standard-issue bayonet of the UPP, it's dulled from heavy use."

/obj/item/attachable/bayonet/upp
	name = "Type 80 bayonet"
	desc = "The standard-issue bayonet of the UPP, the Type 80 is balanced to also function as an effective throwing knife."
	icon_state = "upp_bayonet"
	item_state = "combat_knife"
	attach_icon = "upp_bayonet_a"
	throwforce = MELEE_FORCE_TIER_10 //doubled by throwspeed to 100
	throw_speed = SPEED_REALLY_FAST
	throw_range = 7
	pry_delay = 1 SECONDS

/obj/item/attachable/bayonet/co2
	name = "M8 cartridge bayonet"
	desc = "A back issue USCM approved exclusive for Boots subscribers found in issue #255 'Inside the Night Raider - morale breaking alternatives with 2nd LT. Juliane Gerd'. A pressurized tube runs along the inside of the blade, and a button allows one to inject compressed CO2 into the stab wound. It feels cheap to the touch. Faulty even."
	icon_state = "co2_knife"
	attach_icon = "co2_bayonet_a"
	var/filled = FALSE

/obj/item/attachable/bayonet/co2/update_icon()
	icon_state = "co2_knife[filled ? "-f" : ""]"
	attach_icon = "co2_bayonet[filled ? "-f" : ""]_a"

/obj/item/attachable/bayonet/co2/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/co2_cartridge))
		if(!filled)
			filled = TRUE
			user.visible_message(SPAN_NOTICE("[user] slots a CO2 cartridge into [src]. A second later, \he apparently looks dismayed."), SPAN_WARNING("You slot a fresh CO2 cartridge into [src] and snap the slot cover into place. Only then do you realize \the [W]'s valve broke inside \the [src]. Fuck."))
			playsound(src, 'sound/machines/click.ogg')
			qdel(W)
			update_icon()
			return
		else
			user.visible_message(SPAN_WARNING("[user] fiddles with \the [src]. \He looks frustrated."), SPAN_NOTICE("No way man! You can't seem to pry the existing container out of \the [src]... try a screwdriver?"))
			return
	if(HAS_TRAIT(W, TRAIT_TOOL_SCREWDRIVER) && do_after(user, 2 SECONDS, INTERRUPT_ALL, BUSY_ICON_BUILD))
		user.visible_message(SPAN_WARNING("[user] screws with \the [src], using \a [W]. \He looks very frustrated."), SPAN_NOTICE("You try to pry the cartridge out of the [src], but it's stuck damn deep. Piece of junk..."))
		return
	..()

/obj/item/co2_cartridge //where tf else am I gonna put this?
	name = "CO2 cartridge"
	desc = "A cartridge of compressed CO2 for the M8 cartridge bayonet. Do not consume or puncture."
	icon = 'icons/obj/items/items.dmi'
	icon_state = "co2_cartridge"
	item_state = ""
	w_class = SIZE_TINY

/obj/item/attachable/extended_barrel
	name = "extended barrel"
	desc = "The lengthened barrel speeds up and stabilizes the bullet, increasing velocity and accuracy."
	slot = "muzzle"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "ebarrel"
	attach_icon = "ebarrel_a"
	hud_offset_mod = -3

/obj/item/attachable/extended_barrel/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	velocity_mod = AMMO_SPEED_TIER_1

/obj/item/attachable/heavy_barrel
	name = "barrel charger"
	desc = "A hyper threaded barrel extender that fits to the muzzle of most firearms. Increases bullet speed and velocity.\nGreatly increases projectile damage at the cost of accuracy and firing speed."
	slot = "muzzle"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "hbarrel"
	attach_icon = "hbarrel_a"
	hud_offset_mod = -3

/obj/item/attachable/heavy_barrel/New()
	..()
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_3
	damage_mod = BULLET_DAMAGE_MULT_TIER_6
	delay_mod = FIRE_DELAY_TIER_9

	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_7

/obj/item/attachable/heavy_barrel/Attach(obj/item/weapon/gun/gun)
	if(gun.gun_category == GUN_CATEGORY_SHOTGUN)
		damage_mod = BULLET_DAMAGE_MULT_TIER_1
	else
		damage_mod = BULLET_DAMAGE_MULT_TIER_6
	..()

/obj/item/attachable/compensator
	name = "recoil compensator"
	desc = "A muzzle attachment that reduces recoil by diverting expelled gasses upwards. \nIncreases accuracy and reduces recoil, at the cost of a small amount of weapon damage."
	slot = "muzzle"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "comp"
	attach_icon = "comp_a"
	pixel_shift_x = 17
	hud_offset_mod = -3

/obj/item/attachable/compensator/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	damage_mod = -BULLET_DAMAGE_MULT_TIER_2
	recoil_mod = -RECOIL_AMOUNT_TIER_3

	damage_falloff_mod = 0.1
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_4
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_4


/obj/item/attachable/slavicbarrel
	name = "sniper barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "slavicbarrel"
	desc = "A heavy barrel. CANNOT BE REMOVED."
	slot = "muzzle"

	pixel_shift_x = 20
	pixel_shift_y = 16
	flags_attach_features = NO_FLAGS
	hud_offset_mod = -4

/obj/item/attachable/slavicbarrel/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	scatter_mod = -SCATTER_AMOUNT_TIER_8

/obj/item/attachable/sniperbarrel
	name = "sniper barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "sniperbarrel"
	desc = "A heavy barrel. CANNOT BE REMOVED."
	slot = "muzzle"
	flags_attach_features = NO_FLAGS
	hud_offset_mod = -3

/obj/item/attachable/sniperbarrel/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	scatter_mod = -SCATTER_AMOUNT_TIER_8

/obj/item/attachable/m60barrel
	name = "M60 barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "m60barrel"
	desc = "A heavy barrel. CANNOT BE REMOVED."
	slot = "muzzle"
	flags_attach_features = NO_FLAGS
	hud_offset_mod = -6

/obj/item/attachable/m60barrel/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	scatter_mod = -SCATTER_AMOUNT_TIER_8

/obj/item/attachable/mar50barrel
	name = "MAR-50 barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "mar50barrel"
	desc = "A heavy barrel. CANNOT BE REMOVED."
	slot = "muzzle"
	flags_attach_features = NO_FLAGS
	hud_offset_mod = -6

/obj/item/attachable/mar50barrel/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	scatter_mod = -SCATTER_AMOUNT_TIER_8

/obj/item/attachable/smartbarrel
	name = "smartgun barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "m56_barrel"
	desc = "The very end of the M56 smart gun, featuring a compensator. CANNOT BE REMOVED."
	slot = "muzzle"
	flags_attach_features = NO_FLAGS
	pixel_shift_x = 14
	hud_offset_mod = -4

// Mateba barrels

/obj/item/attachable/mateba
	name = "standard mateba barrel"
	icon = 'icons/obj/items/weapons/guns/attachments/barrel.dmi'
	icon_state = "mateba_medium"
	desc = "A standard mateba barrel. Offers a balance between accuracy and fire rate."
	slot = "special"
	flags_attach_features = NO_FLAGS

/obj/item/attachable/mateba/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3

/obj/item/attachable/mateba/Attach(obj/item/weapon/gun/gun)
	..()
	gun.attachable_offset["muzzle_x"] = 27

/obj/item/attachable/mateba/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	..()
	detaching_gub.attachable_offset["muzzle_x"] = 20

/obj/item/attachable/mateba/dark
	icon_state = "mateba_medium_a"

/obj/item/attachable/mateba/long
	name = "marksman mateba barrel"
	icon_state = "mateba_long"
	desc = "A marksman mateba barrel. Offers a greater accuracy at the cost of fire rate."
	flags_attach_features = NO_FLAGS
	hud_offset_mod = -1

/obj/item/attachable/mateba/long/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_6
	delay_mod = FIRE_DELAY_TIER_7

/obj/item/attachable/mateba/long/Attach(obj/item/weapon/gun/gun)
	..()
	gun.attachable_offset["muzzle_x"] = 27

/obj/item/attachable/mateba/long/dark
	icon_state = "mateba_long_a"

/obj/item/attachable/mateba/short
	name = "snubnose mateba barrel"
	icon_state = "mateba_short"
	desc = "A snubnosed mateba barrel. Offers a fast fire rate at the cost of accuracy."
	hud_offset_mod = 2

/obj/item/attachable/mateba/short/New()
	..()
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_4
	scatter_mod = SCATTER_AMOUNT_TIER_6
	delay_mod = -FIRE_DELAY_TIER_7

/obj/item/attachable/mateba/short/Attach(obj/item/weapon/gun/gun)
	..()
	gun.attachable_offset["muzzle_x"] = 27

/obj/item/attachable/mateba/short/dark
	icon_state = "mateba_short_a"

// ======== Rail attachments ======== //

/obj/item/attachable/reddot
	name = "S5 red-dot sight"
	desc = "An ARMAT S5 red-dot sight. A zero-magnification optic that offers faster, and more accurate target acquisition."
	desc_lore = "An all-weather collimator sight, designated as the AN/PVQ-64 Dot Sight. Equipped with a sunshade to increase clarity in bright conditions and resist weathering. Compact and efficient, a marvel of military design, until you realize that this is actually just an off-the-shelf design that got a military designation slapped on."
	icon = 'icons/obj/items/weapons/guns/attachments/rail.dmi'
	icon_state = "reddot"
	attach_icon = "reddot_a"
	slot = "rail"

/obj/item/attachable/reddot/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	movement_onehanded_acc_penalty_mod = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5

/obj/item/attachable/reflex
	name = "S6 reflex sight"
	desc = "An ARMAT S6 reflex sight. A zero-magnification alternative to iron sights with a more open optic window when compared to the S5 red-dot. Helps to reduce scatter during automated fire."
	desc_lore = "A simple folding reflex sight designated as the AN/PVG-72 Reflex Sight, compatible with most rail systems. Bulky and built to last, it can link with military HUDs for limited point-of-aim calculations."
	icon = 'icons/obj/items/weapons/guns/attachments/rail.dmi'
	icon_state = "reflex"
	attach_icon = "reflex_a"
	slot = "rail"

/obj/item/attachable/reflex/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	burst_scatter_mod = -1
	movement_onehanded_acc_penalty_mod = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5


/obj/item/attachable/flashlight
	name = "rail flashlight"
	desc = "A flashlight, for rails, on guns. Can be toggled on and off. A better light source than standard M3 pattern armor lights."
	icon = 'icons/obj/items/weapons/guns/attachments/rail.dmi'
	icon_state = "flashlight"
	attach_icon = "flashlight_a"
	light_mod = 5
	light_power = 0.3
	slot = "rail"
	matter = list("metal" = 50,"glass" = 20)
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle
	activation_sound = 'sound/handling/light_on_1.ogg'
	deactivation_sound = 'sound/handling/click_2.ogg'
	var/original_state = "flashlight"
	var/original_attach = "flashlight_a"

	var/helm_mounted_light_mod = 3

	var/datum/action/item_action/activation
	var/obj/item/attached_item

/obj/item/attachable/flashlight/on_enter_storage(obj/item/storage/internal/storage)
	..()

	if(!istype(storage, /obj/item/storage/internal))
		return

	if(!istype(storage.master_object, /obj/item/clothing/head/helmet/marine))
		return

	remove_attached_item()

	attached_item = storage.master_object
	RegisterSignal(attached_item, COMSIG_PARENT_QDELETING, PROC_REF(remove_attached_item))
	activation = new /datum/action/item_action/toggle(src, storage.master_object)

	if(ismob(storage.master_object.loc))
		activation.give_to(storage.master_object.loc)

/obj/item/attachable/flashlight/on_exit_storage(obj/item/storage/storage)
	remove_attached_item()
	return ..()

/obj/item/attachable/flashlight/proc/remove_attached_item()
	SIGNAL_HANDLER
	if(!attached_item)
		return
	if(light_on)
		icon_state = original_state
		attach_icon = original_attach
		activate_attachment(attached_item, attached_item.loc, TRUE)
	UnregisterSignal(attached_item, COMSIG_PARENT_QDELETING)
	qdel(activation)
	attached_item.update_icon()
	attached_item = null

/obj/item/attachable/flashlight/ui_action_click(mob/owner, obj/item/holder)
	if(!attached_item)
		. = ..()
	else if(!istype(attached_item, /obj/item/weapon/gun))
		activate_attachment_armor(attached_item, owner)
	else
		activate_attachment(attached_item, owner)

/obj/item/attachable/flashlight/proc/activate_attachment_armor(obj/item/clothing/head/helmet/marine/H, mob/living/user,  override_off = FALSE)
	if(override_off && light_on)
		icon_state = original_state
		attach_icon = original_attach
		H.set_light_range(H.light_range - light_mod)
		H.set_light_power(H.light_power - light_power/2)
		if(!H.light_range)
			H.set_light_on(FALSE)
		light_on = FALSE

		H.update_icon()
		for(var/X in H.actions)
			var/datum/action/action = X
			if(action.target == src)
				action.update_button_icon()
		return

	if(light_on)
		icon_state = original_state
		attach_icon = original_attach
		H.set_light_range(H.light_range - light_mod)
		H.set_light_power(H.light_power - light_power/2)
		if(!H.light_range)
			H.set_light_on(FALSE)
		light_on = FALSE
		playsound(user, deactivation_sound, 15, 1)
	else
		icon_state += "-on"
		attach_icon += "-on"
		H.set_light_range(H.light_range + light_mod)
		H.set_light_power(H.light_power + light_power/2)
		H.set_light_on(TRUE)
		light_on = TRUE
		playsound(user, activation_sound, 15, 1)

	H.update_icon()
	for(var/X in H.actions)
		var/datum/action/action = X
		if(action.target == src)
			action.update_button_icon()
	return TRUE

/obj/item/attachable/flashlight/activate_attachment(obj/item/weapon/gun/gun, mob/living/user, override_off = FALSE)
	if(ismob(gun.loc) && !user)
		user = gun.loc

	if(override_off && gun.flags_gun_features & GUN_FLASHLIGHT_ON)
		icon_state = original_state
		attach_icon = original_attach
		gun.set_light_range(gun.light_range - light_mod)
		gun.set_light_power(gun.light_power - light_power/2)
		if(!gun.light_range)
			gun.flags_gun_features ^= GUN_FLASHLIGHT_ON
			gun.set_light_on(FALSE)
		light_on = FALSE

		gun.update_attachable(slot)
		for(var/X in gun.actions)
			var/datum/action/action = X
			if(action.target == src)
				action.update_button_icon()
		return

	if(!gun.light_range)
		gun.flags_gun_features ^= GUN_FLASHLIGHT_ON

	if(light_on)
		icon_state = original_state
		attach_icon = original_attach
		gun.set_light_range(gun.light_range - light_mod)
		gun.set_light_power(gun.light_power - light_power/2)
		if(!gun.light_range)
			gun.flags_gun_features ^= GUN_FLASHLIGHT_ON
			gun.set_light_on(FALSE)
		light_on = FALSE
		playsound(user, deactivation_sound, 15, 1)
	else
		icon_state += "-on"
		attach_icon += "-on"
		gun.set_light_range(gun.light_range + light_mod)
		gun.set_light_power(gun.light_power + light_power/2)
		gun.set_light_on(TRUE)
		light_on = TRUE
		playsound(user, activation_sound, 15, 1)

	gun.update_attachable(slot)
	for(var/X in gun.actions)
		var/datum/action/action = X
		if(action.target == src)
			action.update_button_icon()
	return TRUE

/obj/item/attachable/flashlight/attackby(obj/item/item, mob/user)
	if(HAS_TRAIT(item, TRAIT_TOOL_SCREWDRIVER))
		to_chat(user, SPAN_NOTICE("You strip the rail flashlight of its mount, converting it to a normal flashlight."))
		if(isstorage(loc))
			var/obj/item/storage/S = loc
			S.remove_from_storage(src)
		if(loc == user)
			user.temp_drop_inv_item(src)
		var/obj/item/device/flashlight/F = new(user)
		user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
		qdel(src) //Delete da old flashlight
	else
		. = ..()

/obj/item/attachable/flashlight/grip //Grip Light is here because it is a child object. Having it further down might cause a future coder a headache.
	name = "underbarrel flashlight grip"
	desc = "Holy smokes RO man, they put a grip on a flashlight! \nReduces recoil and scatter by a tiny amount. Boosts accuracy by a tiny amount. Works as a light source."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "flashgrip"
	attach_icon = "flashgrip_a"
	slot = "under"
	original_state = "flashgrip"
	original_attach = "flashgrip_a"

/obj/item/attachable/flashlight/grip/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/flashlight/grip/attackby(obj/item/item, mob/user)
	if(HAS_TRAIT(item, TRAIT_TOOL_SCREWDRIVER))
		to_chat(user, SPAN_NOTICE("Hold on there cowboy, that grip is bolted on. You are unable to modify it."))
	return

/obj/item/attachable/flashlight/laser_light_combo //Unique attachment for the VP78 based on the fact it has a Laser-Light Module in AVP2010
	name = "VP78 Laser-Light Module"
	desc = "A Laser-Light module for the VP78 Service Pistol which is currently undergoing limited field testing as part of the USCMs next generation pistol program. All VP78 pistols come equipped with the module."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "vplaserlight"
	attach_icon = "vplaserlight_a"
	slot = "under"
	original_state = "vplaserlight"
	original_attach = "vplaserlight_a"

/obj/item/attachable/flashlight/laser_light_combo/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_9
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1

/obj/item/attachable/flashlight/laser_light_combo/attackby(obj/item/combo_light, mob/user)
	if(HAS_TRAIT(combo_light, TRAIT_TOOL_SCREWDRIVER))
		to_chat(user, SPAN_NOTICE("You are unable to modify it."))
	return

/obj/item/attachable/magnetic_harness
	name = "magnetic harness"
	desc = "A magnetically attached harness kit that attaches to the rail mount of a weapon. When dropped, the weapon will sling to any set of USCM armor."
	icon = 'icons/obj/items/weapons/guns/attachments/rail.dmi'
	icon_state = "magnetic"
	attach_icon = "magnetic_a"
	slot = "rail"
	pixel_shift_x = 13
	var/retrieval_slot = WEAR_J_STORE

/obj/item/attachable/magnetic_harness/New()
	..()
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_1
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_1

/obj/item/attachable/magnetic_harness/can_be_attached_to_gun(mob/user, obj/item/weapon/gun/gun)
	if(SEND_SIGNAL(gun, COMSIG_DROP_RETRIEVAL_CHECK) & COMPONENT_DROP_RETRIEVAL_PRESENT)
		to_chat(user, SPAN_WARNING("[gun] already has a retrieval system installed!"))
		return FALSE
	return ..()

/obj/item/attachable/magnetic_harness/Attach(obj/item/weapon/gun/gun)
	. = ..()
	gun.AddElement(/datum/element/drop_retrieval/gun, retrieval_slot)

/obj/item/attachable/magnetic_harness/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	. = ..()
	detaching_gub.RemoveElement(/datum/element/drop_retrieval/gun, retrieval_slot)

/obj/item/attachable/magnetic_harness/lever_sling
	name = "R4T magnetic sling" //please don't make this attachable to any other guns...
	desc = "A custom sling designed for comfortable holstering of a 19th century lever action rifle, for some reason. Contains magnets specifically built to make sure the lever-action rifle never drops from your back, however they somewhat get in the way of the grip."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "r4t-sling"
	attach_icon = "r4t-sling_a"
	slot = "under"
	wield_delay_mod = WIELD_DELAY_VERY_FAST
	retrieval_slot = WEAR_BACK

/obj/item/attachable/magnetic_harness/lever_sling/New()
	..()
	select_gamemode_skin(type)

/obj/item/attachable/magnetic_harness/lever_sling/Attach(obj/item/weapon/gun/gun) //this is so the sling lines up correctly
	. = ..()
	gun.attachable_offset["under_x"] = 15
	gun.attachable_offset["under_y"] = 12


/obj/item/attachable/magnetic_harness/lever_sling/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	. = ..()
	detaching_gub.attachable_offset["under_x"] = 24
	detaching_gub.attachable_offset["under_y"] = 16

/obj/item/attachable/magnetic_harness/lever_sling/select_gamemode_skin(expected_type, list/override_icon_state, list/override_protection)
	. = ..()
	var/new_attach_icon
	switch(SSmapping.configs[GROUND_MAP].map_name) // maploader TODO: json
		if(MAP_ICE_COLONY, MAP_ICE_COLONY_V3, MAP_CORSAT, MAP_SOROKYNE_STRATA)
			attach_icon = new_attach_icon ? new_attach_icon : "s_" + attach_icon
		if(MAP_WHISKEY_OUTPOST, MAP_DESERT_DAM, MAP_BIG_RED, MAP_KUTJEVO)
			attach_icon = new_attach_icon ? new_attach_icon : "d_" + attach_icon
		if(MAP_PRISON_STATION, MAP_PRISON_STATION_V3, MAP_LV522_CHANCES_CLAIM, MAP_SKY_SCRAPER)
			attach_icon = new_attach_icon ? new_attach_icon : "c_" + attach_icon

/obj/item/attachable/scope
	name = "S8 4x telescopic scope"
	icon = 'icons/obj/items/weapons/guns/attachments/rail.dmi'
	icon_state = "sniperscope"
	attach_icon = "sniperscope_a"
	desc = "An ARMAT S8 telescopic eye piece. Fixed at 4x zoom. Press the 'use rail attachment' HUD icon or use the verb of the same name to zoom."
	desc_lore = "An intermediate-power Armat scope designated as the AN/PVQ-31 4x Optic. Fairly basic, but both durable and functional... enough. 780 meters is about as far as one can push the 10x24mm cartridge, really."
	slot = "rail"
	aim_speed_mod = SLOWDOWN_ADS_SCOPE //Extra slowdown when wielded
	wield_delay_mod = WIELD_DELAY_FAST
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle
	var/zoom_offset = 11
	var/zoom_viewsize = 12
	var/allows_movement = 0
	var/accuracy_scoped_buff
	var/delay_scoped_nerf
	var/damage_falloff_scoped_buff
	var/ignore_clash_fog = FALSE
	var/using_scope

/obj/item/attachable/scope/New()
	..()
	delay_mod = FIRE_DELAY_TIER_10
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_1
	movement_onehanded_acc_penalty_mod = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_4
	accuracy_unwielded_mod = 0

	accuracy_scoped_buff = HIT_ACCURACY_MULT_TIER_8 //to compensate initial debuff
	delay_scoped_nerf = FIRE_DELAY_TIER_9 //to compensate initial debuff. We want "high_fire_delay"
	damage_falloff_scoped_buff = -0.4 //has to be negative

/obj/item/attachable/scope/proc/apply_scoped_buff(obj/item/weapon/gun/gun, mob/living/carbon/user)
	if(gun.zoom)
		gun.accuracy_mult += accuracy_scoped_buff
		gun.fire_delay += delay_scoped_nerf
		gun.damage_falloff_mult += damage_falloff_scoped_buff
		using_scope = TRUE
		RegisterSignal(user, COMSIG_LIVING_ZOOM_OUT, PROC_REF(remove_scoped_buff))

/obj/item/attachable/scope/proc/remove_scoped_buff(mob/living/carbon/user, obj/item/weapon/gun/gun)
	SIGNAL_HANDLER
	UnregisterSignal(user, COMSIG_LIVING_ZOOM_OUT)
	using_scope = FALSE
	gun.accuracy_mult -= accuracy_scoped_buff
	gun.fire_delay -= delay_scoped_nerf
	gun.damage_falloff_mult -= damage_falloff_scoped_buff

/obj/item/attachable/scope/activate_attachment(obj/item/weapon/gun/gun, mob/living/carbon/user, turn_off)
	if(turn_off || gun.zoom)
		if(gun.zoom)
			gun.zoom(user, zoom_offset, zoom_viewsize, allows_movement)
		return TRUE

	if(!gun.zoom)
		if(!(gun.flags_item & WIELDED))
			if(user)
				to_chat(user, SPAN_WARNING("You must hold [gun] with two hands to use [src]."))
			return FALSE
		if(MODE_HAS_FLAG(MODE_HVH_BALANCE) && !ignore_clash_fog)
			if(user)
				to_chat(user, SPAN_DANGER("You peer into [src], but it seems to have fogged up. You can't use this!"))
			return FALSE
		else
			gun.zoom(user, zoom_offset, zoom_viewsize, allows_movement)
			apply_scoped_buff(gun,user)
	return TRUE

//variable zoom scopes, they go between 2x and 4x zoom.

#define ZOOM_LEVEL_2X 0
#define ZOOM_LEVEL_4X 1

/obj/item/attachable/scope/variable_zoom
	name = "S10 variable zoom telescopic scope"
	desc = "An ARMAT S10 telescopic eye piece. Can be switched between 2x zoom, which allows the user to move while scoped in, and 4x zoom. Press the 'use rail attachment' HUD icon or use the verb of the same name to zoom."
	attachment_action_type = /datum/action/item_action/toggle
	var/dynamic_aim_slowdown = SLOWDOWN_ADS_MINISCOPE_DYNAMIC
	var/zoom_level = ZOOM_LEVEL_4X

/obj/item/attachable/scope/variable_zoom/Attach(obj/item/weapon/gun/gun)
	. = ..()
	var/mob/living/living
	var/given_zoom_action = FALSE
	if(living && (gun == living.l_hand || gun == living.r_hand))
		give_action(living, /datum/action/item_action/toggle_zoom_level, src, gun)
		given_zoom_action = TRUE
	if(!given_zoom_action)
		new /datum/action/item_action/toggle_zoom_level(src, gun)

/obj/item/attachable/scope/variable_zoom/apply_scoped_buff(obj/item/weapon/gun/gun, mob/living/carbon/user)
	. = ..()
	if(gun.zoom)
		gun.slowdown += dynamic_aim_slowdown

/obj/item/attachable/scope/variable_zoom/remove_scoped_buff(mob/living/carbon/user, obj/item/weapon/gun/gun)
	gun.slowdown -= dynamic_aim_slowdown
	..()

/obj/item/attachable/scope/variable_zoom/proc/toggle_zoom_level()
	if(using_scope)
		to_chat(usr, SPAN_WARNING("You can't change the zoom setting on the [src] while you're looking through it!"))
		return
	if(zoom_level == ZOOM_LEVEL_2X)
		zoom_level = ZOOM_LEVEL_4X
		zoom_offset = 11
		zoom_viewsize = 12
		allows_movement = 0
		to_chat(usr, SPAN_NOTICE("Zoom level switched to 4x"))
		return
	else
		zoom_level = ZOOM_LEVEL_2X
		zoom_offset = 6
		zoom_viewsize = 7
		allows_movement = 1
		to_chat(usr, SPAN_NOTICE("Zoom level switched to 2x"))
		return

/datum/action/item_action/toggle_zoom_level

/datum/action/item_action/toggle_zoom_level/New()
	..()
	name = "Toggle Zoom Level"
	button.name = name

/datum/action/item_action/toggle_zoom_level/action_activate()
	var/obj/item/weapon/gun/gun = holder_item
	var/obj/item/attachable/scope/variable_zoom/S = gun.attachments["rail"]
	S.toggle_zoom_level()

//other variable zoom scopes

/obj/item/attachable/scope/variable_zoom/slavic
	icon_state = "slavicscope"
	attach_icon = "slavicscope"
	desc = "Oppa! Why did you get this off glorious Stalin weapon? Blyat, put back on and do job tovarish. Yankee is not shoot self no?"

/obj/item/attachable/scope/variable_zoom/eva
	name = "RXF-M5 EVA telescopic variable scope"
	icon_state = "rxfm5_eva_scope"
	attach_icon = "rxfm5_eva_scope_a"
	desc = "A civilian-grade scope that can be switched between short and long range magnification, intended for use in extraterrestrial scouting. Looks ridiculous on a pistol."
	aim_speed_mod = 0

#undef ZOOM_LEVEL_2X
#undef ZOOM_LEVEL_4X


/obj/item/attachable/scope/mini
	name = "S4 2x telescopic mini-scope"
	icon_state = "miniscope"
	attach_icon = "miniscope_a"
	desc = "An ARMAT S4 telescoping eye piece. Fixed at a modest 2x zoom. Press the 'use rail attachment' HUD icon or use the verb of the same name to zoom."
	desc_lore = "A light-duty optic, designated as the AN/PVQ-45 2x Optic. Suited towards short to medium-range engagements. Users are advised to zero it often, as the first mass-production batch had a tendency to drift in one direction or another with sustained use."
	slot = "rail"
	zoom_offset = 6
	zoom_viewsize = 7
	allows_movement = TRUE
	aim_speed_mod = 0
	var/dynamic_aim_slowdown = SLOWDOWN_ADS_MINISCOPE_DYNAMIC

/obj/item/attachable/scope/mini/New()
	..()
	delay_mod = 0
	delay_scoped_nerf = FIRE_DELAY_TIER_SMG
	damage_falloff_scoped_buff = -0.2 //has to be negative

/obj/item/attachable/scope/mini/apply_scoped_buff(obj/item/weapon/gun/gun, mob/living/carbon/user)
	. = ..()
	if(gun.zoom)
		gun.slowdown += dynamic_aim_slowdown

/obj/item/attachable/scope/mini/remove_scoped_buff(mob/living/carbon/user, obj/item/weapon/gun/gun)
	gun.slowdown -= dynamic_aim_slowdown
	..()

/obj/item/attachable/scope/mini/flaregun
	wield_delay_mod = 0
	dynamic_aim_slowdown = SLOWDOWN_ADS_MINISCOPE_DYNAMIC

/obj/item/attachable/scope/mini/flaregun/New()
	..()
	delay_mod = 0
	accuracy_mod = 0
	movement_onehanded_acc_penalty_mod = 0
	accuracy_unwielded_mod = 0

	accuracy_scoped_buff = HIT_ACCURACY_MULT_TIER_8
	delay_scoped_nerf = FIRE_DELAY_TIER_8

/obj/item/attachable/scope/mini/hunting
	name = "2x hunting mini-scope"
	icon_state = "huntingscope"
	attach_icon = "huntingscope"
	desc = "This civilian-grade scope is a common sight on hunting rifles due to its cheap price and great optics. Fixed at a modest 2x zoom. Press the 'use rail attachment' HUD icon or use the verb of the same name to zoom."

/obj/item/attachable/scope/mini/nsg23
	name = "W-Y S4 2x advanced telescopic mini-scope"
	desc = "An ARMAT S4 telescoping eye piece, custom-tuned by W-Y scientists to be as ergonomic as possible."
	icon_state = "miniscope_nsg23"
	attach_icon = "miniscope_nsg23_a"
	zoom_offset = 7
	dynamic_aim_slowdown = SLOWDOWN_ADS_NONE

/obj/item/attachable/scope/mini/xm88
	name = "XS-9 targeting relay"
	desc = "An ARMAT XS-9 optical interface. Unlike a traditional scope, this rail-mounted device features no telescoping lens. Instead, the firearm's onboard targeting system relays data directly to the optic for the system operator to reference in realtime."
	icon_state = "boomslang-scope"
	zoom_offset = 7
	dynamic_aim_slowdown = SLOWDOWN_ADS_NONE

/obj/item/attachable/scope/mini/xm88/New()
	..()
	select_gamemode_skin(type)
	attach_icon = icon_state

/obj/item/attachable/scope/mini_iff
	name = "B8 Smart-Scope"
	icon_state = "iffbarrel"
	attach_icon = "iffbarrel_a"
	desc = "An experimental B8 Smart-Scope. Based on the technologies used in the Smart Gun by ARMAT, this sight has integrated IFF systems. It can only attach to the M4RA Battle Rifle and M44 Combat Revolver."
	desc_lore = "An experimental fire-control optic capable of linking into compatible IFF systems on certain weapons, designated the XAN/PVG-110 Smart Scope. Currently programmed for usage with the M4RA battle rifle and M44 Combat Revolver, due to their relatively lower rates of fire. Experimental technology developed by Armat, who have assured that all previously reported issues with false-negative IFF recognitions have been solved. Make sure to check the sight after every op, just in case."
	slot = "rail"
	zoom_offset = 6
	zoom_viewsize = 7
	pixel_shift_y = 15
	var/dynamic_aim_slowdown = SLOWDOWN_ADS_MINISCOPE_DYNAMIC

/obj/item/attachable/scope/mini_iff/New()
	..()
	damage_mod = -BULLET_DAMAGE_MULT_TIER_4
	movement_onehanded_acc_penalty_mod = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_6
	accuracy_unwielded_mod = 0

	accuracy_scoped_buff = HIT_ACCURACY_MULT_TIER_1
	delay_scoped_nerf = 0
	damage_falloff_scoped_buff = 0

/obj/item/attachable/scope/mini_iff/set_bullet_traits()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff)
	))

/obj/item/attachable/scope/mini_iff/activate_attachment(obj/item/weapon/gun/gun, mob/living/carbon/user, turn_off)
	if(do_after(user, 8, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		allows_movement = 1
		. = ..()

/obj/item/attachable/scope/mini_iff/apply_scoped_buff(obj/item/weapon/gun/gun, mob/living/carbon/user)
	. = ..()
	if(gun.zoom)
		gun.slowdown += dynamic_aim_slowdown

/obj/item/attachable/scope/mini_iff/remove_scoped_buff(mob/living/carbon/user, obj/item/weapon/gun/gun)
	gun.slowdown -= dynamic_aim_slowdown
	..()

/obj/item/attachable/scope/slavic
	icon_state = "slavicscope"
	attach_icon = "slavicscope"
	desc = "Oppa! How did you get this off glorious Stalin weapon? Blyat, put back on and do job tovarish. Yankee is not shoot self no?"



// ======== Stock attachments ======== //


/obj/item/attachable/stock //Generic stock parent and related things.
	name = "default stock"
	desc = "If you can read this, someone screwed up. Go Gitlab this and bug a coder."
	icon_state = "stock"
	slot = "stock"
	wield_delay_mod = WIELD_DELAY_VERY_FAST
	melee_mod = 5
	size_mod = 2
	pixel_shift_x = 30
	pixel_shift_y = 14

	var/collapsible = FALSE
	var/stock_activated = TRUE
	var/collapse_delay  = 0
	var/list/deploy_message = list("collapse", "extend")

/obj/item/attachable/stock/proc/apply_on_weapon(obj/item/weapon/gun/gun)
	return TRUE

/obj/item/attachable/stock/activate_attachment(obj/item/weapon/gun/gun, mob/living/carbon/user, turn_off)
	. = ..()

	if(!collapsible)
		return .

	if(turn_off && stock_activated)
		stock_activated = FALSE
		apply_on_weapon(gun)
		return TRUE

	if(!user)
		return TRUE

	if(gun.flags_item & WIELDED)
		to_chat(user, SPAN_NOTICE("You need a free hand to adjust [src]."))
		return TRUE

	if(!do_after(user, collapse_delay, INTERRUPT_INCAPACITATED|INTERRUPT_NEEDHAND, BUSY_ICON_GENERIC, gun, INTERRUPT_DIFF_LOC))
		return FALSE

	stock_activated = !stock_activated
	apply_on_weapon(gun)
	playsound(user, activation_sound, 15, 1)
	var/message = deploy_message[1 + stock_activated]
	to_chat(user, SPAN_NOTICE("You [message] [src]."))

	for(var/X in gun.actions)
		var/datum/action/action = X
		if(istype(action, /datum/action/item_action/toggle))
			action.update_button_icon()

/obj/item/attachable/stock
	icon = 'icons/obj/items/weapons/guns/attachments/stock.dmi'

/obj/item/attachable/stock/shotgun
	name = "M37 wooden stock"
	desc = "A non-standard heavy wooden stock for the M37 Shotgun. More cumbersome than the standard issue stakeout, but reduces recoil and improves accuracy. Allegedly makes a pretty good club in a fight too."
	slot = "stock"
	icon_state = "stock"
	wield_delay_mod = WIELD_DELAY_FAST
	pixel_shift_x = 32
	pixel_shift_y = 15
	hud_offset_mod = 6 //*Very* long sprite.

/obj/item/attachable/stock/shotgun/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8
	//but at the same time you are slow when 2 handed
	aim_speed_mod = CONFIG_GET(number/slowdown_med)

	matter = list("wood" = 2000)

	select_gamemode_skin(type)

/obj/item/attachable/stock/double
	name = "double barrel shotgun stock"
	desc = "A chunky piece of wood coated in varnish and age."
	slot = "stock"
	icon_state = "db_stock"
	wield_delay_mod = WIELD_DELAY_NONE//part of the gun's base stats
	flags_attach_features = NO_FLAGS
	pixel_shift_x = 32
	pixel_shift_y = 15
	hud_offset_mod = 2

/obj/item/attachable/stock/double/New()
	..()

/obj/item/attachable/stock/mou53
	name = "MOU53 tactical stock"
	desc = "A metal stock fitted specifically for the MOU53 break action shotgun."
	icon_state = "ou_stock"
	hud_offset_mod = 5

/obj/item/attachable/stock/mou53/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/stock/r4t
	name = "R4T scouting stock"
	desc = "A wooden stock designed for the R4T lever-action rifle, designed to withstand harsh environments. It increases weapon stability but really gets in the way."
	icon_state = "r4t-stock"
	wield_delay_mod = WIELD_DELAY_SLOW
	hud_offset_mod = 6

/obj/item/attachable/stock/r4t/New()
	..()
	select_gamemode_skin(type)
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_4

/obj/item/attachable/stock/xm88
	name = "XM88 padded stock"
	desc = "A specially made compound polymer stock reinforced with aluminum rods and thick rubber padding to shield the user from recoil. Fitted specifically for the XM88 Heavy Rifle."
	icon_state = "boomslang-stock"
	wield_delay_mod = WIELD_DELAY_NORMAL
	hud_offset_mod = 6

/obj/item/attachable/stock/xm88/New()
	..()
	select_gamemode_skin(type)
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_4

/obj/item/attachable/stock/tactical
	name = "MK221 tactical stock"
	desc = "A metal stock made for the MK221 tactical shotgun."
	icon_state = "tactical_stock"
	hud_offset_mod = 6

/obj/item/attachable/stock/tactical/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/stock/type23
	name = "Type 23 standard stock"
	desc = "A stamped metal stock with internal recoil springs designed to absorb the ridiculous kick the 8 Gauge shotgun causes when fired. Not recommended to remove."
	icon_state = "type23_stock"
	pixel_shift_x = 15
	pixel_shift_y = 15
	hud_offset_mod = 2

/obj/item/attachable/stock/type23/New()
	..()
	//2h
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//1h
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/stock/slavic
	name = "wooden stock"
	desc = "A non-standard heavy wooden stock for Slavic firearms."
	icon_state = "slavicstock"
	pixel_shift_x = 32
	pixel_shift_y = 13
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 0 //Already attached to base sprite.

/obj/item/attachable/stock/slavic/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	delay_mod = FIRE_DELAY_TIER_7
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/stock/hunting
	name = "wooden stock"
	desc = "The non-detachable stock of a Basira-Armstrong rifle."
	icon_state = "huntingstock"
	pixel_shift_x = 41
	pixel_shift_y = 10
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 6

/obj/item/attachable/stock/hunting/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8

/obj/item/attachable/stock/hg3712
	name = "hg3712 stock"
	desc = "The non-detachable stock of a HG 37-12 pump shotgun."
	icon_state = "hg3712_stock"
	pixel_shift_x = 41
	pixel_shift_y = 10
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 6

/obj/item/attachable/stock/hg3712/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_4
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8

/obj/item/attachable/stock/hg3712/m3717
	name = "hg3717 stock"
	desc = "The non-detachable stock of a M37-17 pump shotgun."
	icon_state = "hg3717_stock"

/obj/item/attachable/stock/rifle
	name = "M41A solid stock"
	desc = "A rare stock distributed in small numbers to USCM forces. Compatible with the M41A, this stock reduces recoil and improves accuracy, but at a reduction to handling and agility. Also enhances the thwacking of things with the stock-end of the rifle."
	slot = "stock"
	melee_mod = 10
	size_mod = 1
	icon_state = "riflestock"
	attach_icon = "riflestock_a"
	pixel_shift_x = 40
	pixel_shift_y = 10
	wield_delay_mod = WIELD_DELAY_FAST
	hud_offset_mod = 3

/obj/item/attachable/stock/rifle/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_5
	recoil_mod = -RECOIL_AMOUNT_TIER_3
	scatter_mod = -SCATTER_AMOUNT_TIER_7
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_4
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8
	//but at the same time you are slow when 2 handed
	aim_speed_mod = CONFIG_GET(number/slowdown_med)

/obj/item/attachable/stock/rifle/collapsible
	name = "M41A folding stock"
	desc = "The standard back end of any gun starting with \"M41\". Compatible with the M41A series, this stock reduces recoil and improves accuracy, but at a reduction to handling and agility. Also enhances the thwacking of things with the stock-end of the rifle."
	slot = "stock"
	melee_mod = 5
	size_mod = 1
	icon_state = "m41_folding"
	attach_icon = "m41_folding_a"
	pixel_shift_x = 40
	pixel_shift_y = 14
	hud_offset_mod = 3
	collapsible = TRUE
	stock_activated = FALSE
	wield_delay_mod = WIELD_DELAY_NONE //starts collapsed so no delay mod
	collapse_delay = 0.5 SECONDS
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle

/obj/item/attachable/stock/rifle/collapsible/New()
	..()

	//rifle stock starts collapsed so we zero out everything
	accuracy_mod = 0
	recoil_mod = 0
	scatter_mod = 0
	movement_onehanded_acc_penalty_mod = 0
	accuracy_unwielded_mod = 0
	recoil_unwielded_mod = 0
	scatter_unwielded_mod = 0
	aim_speed_mod = 0
	wield_delay_mod = WIELD_DELAY_NONE

/obj/item/attachable/stock/rifle/collapsible/apply_on_weapon(obj/item/weapon/gun/gun)
	if(stock_activated)
		accuracy_mod = HIT_ACCURACY_MULT_TIER_2
		recoil_mod = -RECOIL_AMOUNT_TIER_5
		scatter_mod = -SCATTER_AMOUNT_TIER_9
		//it makes stuff worse when one handed
		movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
		accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
		recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
		scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8
		aim_speed_mod = CONFIG_GET(number/slowdown_med)
		hud_offset_mod = 5
		icon_state = "m41_folding_on"
		attach_icon = "m41_folding_a_on"
		wield_delay_mod = WIELD_DELAY_VERY_FAST //added 0.2 seconds for wield, basic solid stock adds 0.4

	else
		accuracy_mod = 0
		recoil_mod = 0
		scatter_mod = 0
		movement_onehanded_acc_penalty_mod = 0
		accuracy_unwielded_mod = 0
		recoil_unwielded_mod = 0
		scatter_unwielded_mod = 0
		aim_speed_mod = 0
		hud_offset_mod = 3
		icon_state = "m41_folding"
		attach_icon = "m41_folding_a"
		wield_delay_mod = WIELD_DELAY_NONE //stock is folded so no wield delay

	gun.recalculate_attachment_bonuses()
	gun.update_overlays(src, "stock")

/obj/item/attachable/stock/m16
	name = "M16 bump stock"
	desc = "Technically illegal in the state of California."
	icon_state = "m16_stock"
	attach_icon = "m16_stock"
	wield_delay_mod = WIELD_DELAY_MIN
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 3

/obj/item/attachable/stock/m16/New()//no stats, its cosmetic
	..()

/obj/item/attachable/stock/m16/xm177
	name = "collapsible M16 stock"
	desc = "Very illegal in the state of California."
	icon_state = "m16_folding"
	attach_icon = "m16_folding"
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 3
	collapsible = TRUE
	stock_activated = FALSE
	wield_delay_mod = WIELD_DELAY_NONE //starts collapsed so no delay mod
	collapse_delay = 0.5 SECONDS
	flags_attach_features = ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle

/obj/item/attachable/stock/m16/xm177/Initialize()
	.=..()
	accuracy_mod = 0
	recoil_mod = 0
	scatter_mod = 0
	movement_onehanded_acc_penalty_mod = 0
	accuracy_unwielded_mod = 0
	recoil_unwielded_mod = 0
	scatter_unwielded_mod = 0
	aim_speed_mod = 0
	wield_delay_mod = WIELD_DELAY_NONE

/obj/item/attachable/stock/m16/xm177/apply_on_weapon(obj/item/weapon/gun/gun)
	if(stock_activated)
		accuracy_mod = HIT_ACCURACY_MULT_TIER_2
		recoil_mod = -RECOIL_AMOUNT_TIER_5
		scatter_mod = -SCATTER_AMOUNT_TIER_9
		aim_speed_mod = CONFIG_GET(number/slowdown_med)
		hud_offset_mod = 5
		icon_state = "m16_folding"
		attach_icon = "m16_folding_on"
		wield_delay_mod = WIELD_DELAY_VERY_FAST

	else
		accuracy_mod = 0
		recoil_mod = 0
		scatter_mod = 0
		movement_onehanded_acc_penalty_mod = 0
		accuracy_unwielded_mod = 0
		recoil_unwielded_mod = 0
		scatter_unwielded_mod = 0
		aim_speed_mod = 0
		hud_offset_mod = 3
		icon_state = "m16_folding"
		attach_icon = "m16_folding"
		wield_delay_mod = WIELD_DELAY_NONE //stock is folded so no wield delay
	gun.recalculate_attachment_bonuses()
	gun.update_overlays(src, "stock")


/obj/item/attachable/stock/ar10
	name = "AR10 wooden stock"
	desc = "The spring's in here, don't take it off!"
	icon_state = "ar10_stock"
	attach_icon = "ar10_stock"
	wield_delay_mod = WIELD_DELAY_MIN
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 3

/obj/item/attachable/stock/ar10/New()//no stats, its cosmetic
	..()

/obj/item/attachable/stock/m79
	name = "M79 hardened polykevlon stock"
	desc = "Helps to mitigate the recoil of launching a 40mm grenade. Fits only to the M79."
	icon_state = "m79_stock"
	icon_state = "m79_stock_a"
	wield_delay_mod = WIELD_DELAY_NONE
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 2

/obj/item/attachable/stock/mod88
	name = "Mod 88 burst stock"
	desc = "Increases the fire rate and burst amount on the Mod 88. Some versions act as a holster for the weapon when un-attached. This is a test item and should not be used in normal gameplay (yet)."
	icon_state = "mod88_stock"
	attach_icon = "mod88_stock_a"
	wield_delay_mod = WIELD_DELAY_FAST
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 4
	size_mod = 2
	melee_mod = 5

/obj/item/attachable/stock/mod88/New()
	..()
	//2h
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	recoil_mod = -RECOIL_AMOUNT_TIER_2
	scatter_mod = -SCATTER_AMOUNT_TIER_7
	burst_scatter_mod = -1
	burst_mod = BURST_AMOUNT_TIER_2
	delay_mod = -FIRE_DELAY_TIER_9
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_4
	//1h
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1
	recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_5
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_10

/obj/item/attachable/stock/carbine
	name = "L42 synthetic stock"
	desc = "A special issue stock made of sturdy, yet lightweight materials. Attaches to the L42A Battle Rifle. Not effective as a blunt force weapon."
	slot = "stock"
	size_mod = 1
	icon_state = "l42stock"
	attach_icon = "l42stock_a"
	pixel_shift_x = 37
	pixel_shift_y = 8
	wield_delay_mod = WIELD_DELAY_NORMAL
	hud_offset_mod = 2

/obj/item/attachable/stock/carbine/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_6
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8

/obj/item/attachable/stock/carbine/wood
	name = "ABR-40 \"wooden\" stock"
	desc = "The default \"wooden\" stock for the ABR-40 hunting rifle, the civilian version of the military L42A battle rifle. Theoretically compatible with an L42. Wait, did you just take the stock out of a weapon with no grip...? Great job, genius."
	icon_state = "abr40stock"
	attach_icon = "abr40stock_a"
	melee_mod = 6
	wield_delay_mod = WIELD_DELAY_FAST

/obj/item/attachable/stock/carbine/wood/Initialize() // The gun is meant to be effectively unusable without the attachment.
	. = ..()
	accuracy_mod = (HIT_ACCURACY_MULT_TIER_6) + HIT_ACCURACY_MULT_TIER_10
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = (-SCATTER_AMOUNT_TIER_8) - SCATTER_AMOUNT_TIER_5

/obj/item/attachable/stock/carbine/wood/tactical
	name = "ABR-40 tactical stock"
	desc = "An ABR-40 stock with a sleek paintjob. Wait, did you just take the stock out of a weapon with no grip...? Great job, genius."
	icon_state = "abr40stock_tac"
	attach_icon = "abr40stock_tac_a"

/obj/item/attachable/stock/rifle/marksman
	name = "M41A marksman stock"
	icon_state = "m4markstock"
	attach_icon = "m4markstock"
	flags_attach_features = NO_FLAGS
	hud_offset_mod = 2

/obj/item/attachable/stock/twobore
	name = "heavy wooden stock"
	icon_state = "twobore_stock"
	attach_icon = "twobore_stock"
	slot = "stock"
	wield_delay_mod = WIELD_DELAY_NONE
	flags_attach_features = NO_FLAGS
	melee_mod = 0 //Integrated attachment for visuals, stats handled on main gun.
	size_mod = 0
	pixel_shift_x = 24
	pixel_shift_y = 16
	hud_offset_mod = 10 //A sprite long enough to touch the Moon.

/obj/item/attachable/m4ra_barrel
	name = "M4RA barrel"
	desc = "This isn't supposed to be seperated from the gun, how'd this happen?"
	icon_state = "m4ra_barrel"
	attach_icon = "m4ra_barrel"
	slot = "special"
	wield_delay_mod = WIELD_DELAY_NONE
	flags_attach_features = NO_FLAGS
	melee_mod = 0 //Integrated attachment for visuals, stats handled on main gun.
	size_mod = 0

/obj/item/attachable/m4ra_barrel/New()
	..()
	select_gamemode_skin(type)

/obj/item/attachable/m4ra_barrel/select_gamemode_skin(expected_type, list/override_icon_state, list/override_protection)
	. = ..()
	var/new_attach_icon
	switch(SSmapping.configs[GROUND_MAP].map_name) // maploader TODO: json
		if(MAP_ICE_COLONY, MAP_ICE_COLONY_V3, MAP_CORSAT, MAP_SOROKYNE_STRATA)
			attach_icon = new_attach_icon ? new_attach_icon : "s_" + attach_icon
		if(MAP_WHISKEY_OUTPOST, MAP_DESERT_DAM, MAP_BIG_RED, MAP_KUTJEVO)
			attach_icon = new_attach_icon ? new_attach_icon : "d_" + attach_icon
		if(MAP_PRISON_STATION, MAP_PRISON_STATION_V3, MAP_LV522_CHANCES_CLAIM)
			attach_icon = new_attach_icon ? new_attach_icon : "c_" + attach_icon


/obj/item/attachable/m4ra_barrel_custom
	name = "custom M4RA barrel"
	desc = "This isn't supposed to be seperated from the gun, how'd this happen?"
	icon_state = "m4ra_custom_barrel"
	attach_icon = "m4ra_custom_barrel"
	slot = "special"
	wield_delay_mod = WIELD_DELAY_NONE
	flags_attach_features = NO_FLAGS
	melee_mod = 0 //Integrated attachment for visuals, stats handled on main gun.
	size_mod = 0

/obj/item/attachable/m4ra_barrel_custom/New()
	..()
	select_gamemode_skin(type)

/obj/item/attachable/m4ra_barrel_custom/select_gamemode_skin(expected_type, list/override_icon_state, list/override_protection)
	. = ..()
	var/new_attach_icon
	switch(SSmapping.configs[GROUND_MAP].map_name) // maploader TODO: json
		if(MAP_ICE_COLONY, MAP_ICE_COLONY_V3, MAP_CORSAT, MAP_SOROKYNE_STRATA)
			attach_icon = new_attach_icon ? new_attach_icon : "s_" + attach_icon
		if(MAP_WHISKEY_OUTPOST, MAP_DESERT_DAM, MAP_BIG_RED, MAP_KUTJEVO)
			attach_icon = new_attach_icon ? new_attach_icon : "d_" + attach_icon
		if(MAP_PRISON_STATION, MAP_PRISON_STATION_V3, MAP_LV522_CHANCES_CLAIM)
			attach_icon = new_attach_icon ? new_attach_icon : "c_" + attach_icon

/obj/item/attachable/stock/smg
	name = "submachinegun stock"
	desc = "A rare ARMAT stock distributed in small numbers to USCM forces. Compatible with the M39, this stock reduces recoil and improves accuracy, but at a reduction to handling and agility. Seemingly a bit more effective in a brawl"
	slot = "stock"
	melee_mod = 15
	size_mod = 1
	icon_state = "smgstock"
	attach_icon = "smgstock_a"
	pixel_shift_x = 42
	pixel_shift_y = 11
	wield_delay_mod = WIELD_DELAY_FAST
	hud_offset_mod = 5

/obj/item/attachable/stock/smg/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_7
	recoil_mod = -RECOIL_AMOUNT_TIER_3
	scatter_mod = -SCATTER_AMOUNT_TIER_6
	delay_mod = 0
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	aim_speed_mod = CONFIG_GET(number/slowdown_low)


/obj/item/attachable/stock/smg/collapsible
	name = "submachinegun folding stock"
	desc = "A Kirchner brand K2 M39 folding stock, standard issue in the USCM. The stock, when extended, reduces recoil and improves accuracy, but at a reduction to handling and agility. Seemingly a bit more effective in a brawl. This stock can collapse in, removing almost all positive and negative effects, however it slightly increases spread due to weapon being off-balanced by the collapsed stock."
	slot = "stock"
	melee_mod = 10
	size_mod = 1
	icon_state = "smgstockc"
	attach_icon = "smgstockc_a"
	pixel_shift_x = 43
	pixel_shift_y = 11
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle
	hud_offset_mod = 5
	collapsible = TRUE


/obj/item/attachable/stock/smg/collapsible/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	wield_delay_mod = WIELD_DELAY_FAST
	delay_mod = 0
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_10
	//but at the same time you are slowish when 2 handed
	aim_speed_mod = CONFIG_GET(number/slowdown_low)


/obj/item/attachable/stock/smg/collapsible/apply_on_weapon(obj/item/weapon/gun/gun)
	if(stock_activated)
		scatter_unwielded_mod = SCATTER_AMOUNT_TIER_10
		size_mod = 1
		aim_speed_mod = CONFIG_GET(number/slowdown_low)
		wield_delay_mod = WIELD_DELAY_FAST
		movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
		accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
		recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
		hud_offset_mod = 5
		icon_state = "smgstockc"
		attach_icon = "smgstockc_a"

	else
		scatter_unwielded_mod = 0
		size_mod = 0
		aim_speed_mod = 0
		wield_delay_mod = 0
		movement_onehanded_acc_penalty_mod = 0
		accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_1
		recoil_unwielded_mod = RECOIL_AMOUNT_TIER_5
		hud_offset_mod = 3
		icon_state = "smgstockcc"
		attach_icon = "smgstockcc_a"

	//don't *= -1 on debuffs, you'd actually be making than without stock when it's collapsed.
	accuracy_mod *= -1
	recoil_mod *= -1
	scatter_mod *= -1

	gun.recalculate_attachment_bonuses()
	gun.update_overlays(src, "stock")

/obj/item/attachable/stock/smg/collapsible/brace
	name = "submachinegun arm brace"
	desc = "A specialized stock for use on an M39 submachine gun. It makes one handing more accurate at the expense of burst amount. Wielding the weapon with this stock attached confers a major inaccuracy and recoil debuff."
	size_mod = 1
	icon_state = "smg_brace"
	attach_icon = "smg_brace_a"
	pixel_shift_x = 43
	pixel_shift_y = 11
	collapse_delay = 2.5 SECONDS
	stock_activated = FALSE
	deploy_message = list("unlock","lock")
	hud_offset_mod = 4

/obj/item/attachable/stock/smg/collapsible/brace/New()
	..()
	//Emulates two-handing an SMG.
	burst_mod = -BURST_AMOUNT_TIER_3 //2 shots instead of 5.

	accuracy_mod = -HIT_ACCURACY_MULT_TIER_3
	scatter_mod = SCATTER_AMOUNT_TIER_8
	recoil_mod = RECOIL_AMOUNT_TIER_2
	aim_speed_mod = 0
	wield_delay_mod = WIELD_DELAY_NORMAL//you shouldn't be wielding it anyways

/obj/item/attachable/stock/smg/collapsible/brace/apply_on_weapon(obj/item/weapon/gun/gun)
	if(stock_activated)
		gun.flags_item |= NODROP
		accuracy_mod = -HIT_ACCURACY_MULT_TIER_3
		scatter_mod = SCATTER_AMOUNT_TIER_8
		recoil_mod = RECOIL_AMOUNT_TIER_2 //Hurts pretty bad if it's wielded.
		accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_4
		recoil_unwielded_mod = -RECOIL_AMOUNT_TIER_4
		movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_4 //Does well if it isn't.
		hud_offset_mod = 5
		icon_state = "smg_brace_on"
		attach_icon = "smg_brace_a_on"
	else
		gun.flags_item &= ~NODROP
		accuracy_mod = 0
		scatter_mod = 0
		recoil_mod = 0
		accuracy_unwielded_mod = 0
		recoil_unwielded_mod = 0
		movement_onehanded_acc_penalty_mod = 0 //Does pretty much nothing if it's not activated.
		hud_offset_mod = 4
		icon_state = "smg_brace"
		attach_icon = "smg_brace_a"

	gun.recalculate_attachment_bonuses()
	gun.update_overlays(src, "stock")

/obj/item/attachable/stock/revolver
	name = "M44 magnum sharpshooter stock"
	desc = "A wooden stock modified for use on a 44-magnum. Increases accuracy and reduces recoil at the expense of handling and agility. Less effective in melee as well."
	slot = "stock"
	melee_mod = -5
	size_mod = 1
	icon_state = "44stock"
	pixel_shift_x = 35
	pixel_shift_y = 19
	wield_delay_mod = WIELD_DELAY_FAST
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle
	hud_offset_mod = 7 //Extremely long.
	var/folded = FALSE
	var/list/allowed_hat_items = list(
					/obj/item/ammo_magazine/revolver,
					/obj/item/ammo_magazine/revolver/marksman,
					/obj/item/ammo_magazine/revolver/heavy)

/obj/item/attachable/stock/revolver/New()
	..()
	//it makes stuff much better when two-handed
	accuracy_mod = HIT_ACCURACY_MULT_TIER_7
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	scatter_mod = -SCATTER_AMOUNT_TIER_8
	//it makes stuff much worse when one handed
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	recoil_unwielded_mod = RECOIL_AMOUNT_TIER_4
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_8
	//but at the same time you are slow when 2 handed
	aim_speed_mod = CONFIG_GET(number/slowdown_med)


/obj/item/attachable/stock/revolver/activate_attachment(obj/item/weapon/gun/gun, mob/living/carbon/user, turn_off)
	var/obj/item/weapon/gun/revolver/m44/R = gun
	if(!istype(R))
		return 0

	if(!user)
		return 1

	if(user.action_busy)
		return

	if(R.flags_item & WIELDED)
		if(folded)
			to_chat(user, SPAN_NOTICE("You need a free hand to unfold [src]."))
		else
			to_chat(user, SPAN_NOTICE("You need a free hand to fold [src]."))
		return 0

	if(!do_after(user, 15, INTERRUPT_INCAPACITATED|INTERRUPT_NEEDHAND, BUSY_ICON_GENERIC, gun, INTERRUPT_DIFF_LOC))
		return

	playsound(user, activation_sound, 15, 1)

	if(folded)
		to_chat(user, SPAN_NOTICE("You unfold [src]."))
		R.flags_equip_slot &= ~SLOT_WAIST
		R.folded = FALSE
		icon_state = "44stock"
		size_mod = 1
		hud_offset_mod = 7
		gun.recalculate_attachment_bonuses()
	else
		to_chat(user, SPAN_NOTICE("You fold [src]."))
		R.flags_equip_slot |= SLOT_WAIST // Allow to be worn on the belt when folded
		R.folded = TRUE // We can't shoot anymore, its folded
		icon_state = "44stock_folded"
		size_mod = 0
		hud_offset_mod = 4
		gun.recalculate_attachment_bonuses()
	folded = !folded
	gun.update_overlays(src, "stock")

// If it is activated/folded when we attach it, re-apply the things
/obj/item/attachable/stock/revolver/Attach(obj/item/weapon/gun/gun)
	..()
	var/obj/item/weapon/gun/revolver/m44/R = gun
	if(!istype(R))
		return 0

	if(folded)
		R.flags_equip_slot |= SLOT_WAIST
		R.folded = TRUE
	else
		R.flags_equip_slot &= ~SLOT_WAIST //Can't wear it on the belt slot with stock on when we attach it first time.

// When taking it off we want to undo everything not statwise
/obj/item/attachable/stock/revolver/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	..()
	var/obj/item/weapon/gun/revolver/m44/R = detaching_gub
	if(!istype(R))
		return 0

	if(folded)
		R.folded = FALSE
	else
		R.flags_equip_slot |= SLOT_WAIST

/obj/item/attachable/stock/nsg23
	name = "NSG 23 stock"
	desc = "If you can read this, someone screwed up. Go Github this and bug a coder."
	icon_state = "nsg23_stock"
	slot = "stock"
	wield_delay_mod = WIELD_DELAY_NONE
	melee_mod = 5
	size_mod = 2
	pixel_shift_x = 21
	pixel_shift_y = 20
	hud_offset_mod = 2

// ======== Underbarrel Attachments ======== //


/obj/item/attachable/attached_gun
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	attachment_action_type = /datum/action/item_action/toggle
	//Some attachments may be fired. So here are the variables related to that.
	var/max_range 		= 0 //Determines # of tiles distance the attachable can fire, if it's not a projectile.
	var/last_fired 	//When the attachment was last fired.
	var/attachment_firing_delay = 0 //the delay between shots, for attachments that fires stuff
	var/fire_sound = null //Sound to play when firing it alternately
	var/gun_original_damage_mult = 1 //so you don't buff the underbarrell gun with charger for the wrong weapon
	var/gun_deactivate_sound = 'sound/weapons/handling/gun_underbarrel_deactivate.ogg'//allows us to give the attached gun unique activate and de-activate sounds. Not used yet.
	var/gun_activate_sound  = 'sound/weapons/handling/gun_underbarrel_activate.ogg'
	var/unload_sound = 'sound/weapons/gun_shotgun_shell_insert.ogg'

	/// An assoc list in the format list(/datum/element/bullet_trait_to_give = list(...args))
	/// that will be given to the projectiles of the attached gun
	var/list/list/traits_to_give_attached


/obj/item/attachable/attached_gun/activate_attachment(obj/item/weapon/gun/gun, mob/living/user, turn_off)
	if(gun.active_attachable == src)
		gun.active_attachable = null
		var/diff = gun.damage_mult - 1 //so that if we buffed gun in process, it still does stuff
		//yeah you can cheat by placing BC after switching to underbarrell, but that is one time and we can skip it for sake of optimization
		gun.damage_mult = gun_original_damage_mult + diff
		icon_state = initial(icon_state)
		if(user)
			to_chat(user, SPAN_NOTICE("You are no longer using [src]."))
			playsound(user, gun_deactivate_sound, 30, 1)
			update_ammo_hud(user)

	else if(!turn_off)
		gun.active_attachable = src
		gun_original_damage_mult = gun.damage_mult
		gun.damage_mult = 1
		icon_state += "-on"
		if(user)
			to_chat(user, SPAN_NOTICE("You are now using [src]."))
			playsound(user, gun_activate_sound, 60, 1)
			update_ammo_hud(user)

	for(var/X in gun.actions)
		var/datum/action/action = X
		action.update_button_icon()

	return TRUE

/obj/item/attachable/attached_gun/proc/update_ammo_hud(mob/living/user)
	user?.hud_used.update_ammo_hud(src, get_attachment_ammo_type(), get_attachment_ammo_count())

/obj/item/attachable/attached_gun/proc/get_attachment_ammo_type()
	return null

/obj/item/attachable/attached_gun/proc/get_attachment_ammo_count()
	return FALSE


//The requirement for an attachable being alt fire is AMMO CAPACITY > 0.
/obj/item/attachable/attached_gun/grenade
	name = "underslung grenade launcher"
	desc = "A weapon-mounted, reloadable grenade launcher."
	icon_state = "grenade"
	attach_icon = "grenade_a"
	w_class = SIZE_MEDIUM
	max_rounds = 3
	max_range = 7
	slot = "under"
	fire_sound = 'sound/weapons/gun_m92_attachable.ogg'
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION|ATTACH_RELOADABLE|ATTACH_WEAPON
	var/grenade_pass_flags
	var/breech_open = FALSE // is the UGL open for loading?
	var/cocked = TRUE // has the UGL been cocked via opening and closing the breech?
	var/open_sound = 'sound/weapons/handling/ugl_open.ogg'
	var/close_sound = 'sound/weapons/handling/ugl_close.ogg'

/obj/item/attachable/attached_gun/grenade/Initialize()
	. = ..()
	grenade_pass_flags = PASS_HIGH_OVER|PASS_MOB_THRU

/obj/item/attachable/attached_gun/grenade/New()
	..()
	attachment_firing_delay = FIRE_DELAY_TIER_4 * 3

/obj/item/attachable/attached_gun/grenade/get_examine_text(mob/user)
	. = ..()
	if(ammo_position)
		. += "It has [ammo_position] grenade\s left."
	else
		. += "It's empty."

/obj/item/attachable/attached_gun/grenade/get_attachment_ammo_type()
	if(ammo_position)
		var/obj/item/explosive/grenade/gun = current_rounds[ammo_position]
		return list(gun.hud_state, gun.hud_state_empty)
	else
		return list("grenade_empty", "grenade_empty")

/obj/item/attachable/attached_gun/grenade/get_attachment_ammo_count()
	return ammo_position

/obj/item/attachable/attached_gun/grenade/unique_action(mob/user)
	if(!ishuman(usr))
		return
	if(!user.can_action || user.is_mob_restrained() || !user.loc || !isturf(usr.loc))
		to_chat(user, SPAN_WARNING("Not right now."))
		return

	var/obj/item/weapon/gun/gun = user.get_held_item()
	if(!istype(gun))
		gun = user.get_inactive_hand()
	if(!istype(gun) && gun != null)
		gun = user.get_active_hand()
	if(!gun)
		to_chat(user, SPAN_WARNING("You need to hold \the [src] to do that"))
		return

	pump(user)

/obj/item/attachable/attached_gun/grenade/update_icon()
	. = ..()
	attach_icon = initial(attach_icon)
	icon_state = initial(icon_state)
	if(breech_open)
		attach_icon += "-open"
		icon_state += "-open"
	if(istype(loc, /obj/item/weapon/gun))
		var/obj/item/weapon/gun/gun = loc
		gun.update_attachable(slot)

/obj/item/attachable/attached_gun/grenade/proc/pump(mob/user) //for want of a better proc name
	if(breech_open) // if it was ALREADY open
		breech_open = FALSE
		cocked = TRUE // by closing the gun we have cocked it and readied it to fire
		to_chat(user, SPAN_NOTICE("You close \the [src]'s breech, cocking it!"))
		playsound(src, close_sound, 15, 1)
	else
		breech_open = TRUE
		cocked = FALSE
		to_chat(user, SPAN_NOTICE("You open \the [src]'s breech!"))
		playsound(src, open_sound, 15, 1)
	update_icon()

/obj/item/attachable/attached_gun/grenade/reload_attachment(obj/item/explosive/grenade/gun, mob/user)
	if(!breech_open)
		to_chat(user, SPAN_WARNING("\The [src]'s breech must be open to load grenades! (use unique-action)"))
		return
	if(!istype(gun) || istype(gun, /obj/item/explosive/grenade/spawnergrenade/))
		to_chat(user, SPAN_WARNING("[src] doesn't accept that type of grenade."))
		return
	if(!gun.active) //can't load live grenades
		if(!gun.underslug_launchable)
			to_chat(user, SPAN_WARNING("[src] doesn't accept that type of grenade."))
			return
		if(ammo_position >= max_rounds)
			to_chat(user, SPAN_WARNING("[src] is full."))
		else
			playsound(user, 'sound/weapons/grenade_insert.wav', 25, 1)
			ammo_position++
			current_rounds[ammo_position] = gun
			to_chat(user, SPAN_NOTICE("You load \the [gun] into \the [src]."))
			user.drop_inv_item_to_loc(gun, src)
			update_ammo_hud(user)

/obj/item/attachable/attached_gun/grenade/fire_attachment(atom/target,obj/item/weapon/gun/gun,mob/living/user)
	if(!(gun.flags_item & WIELDED))
		if(user)
			to_chat(user, SPAN_WARNING("You must hold [gun] with two hands to use \the [src]."))
		return
	if(breech_open)
		if(user)
			to_chat(user, SPAN_WARNING("You must close the breech to fire \the [src]!"))
			playsound(user, 'sound/weapons/gun_empty.ogg', 50, TRUE, 5)
		return
	if(!cocked)
		if(user)
			to_chat(user, SPAN_WARNING("You must cock \the [src] to fire it! (open and close the breech)"))
			playsound(user, 'sound/weapons/gun_empty.ogg', 50, TRUE, 5)
		return
	if(get_dist(user,target) > max_range)
		to_chat(user, SPAN_WARNING("Too far to fire the attachment!"))
		playsound(user, 'sound/weapons/gun_empty.ogg', 50, TRUE, 5)
		return
	if(ammo_position > 0 && ..())
		prime_grenade(target,gun,user)

/obj/item/attachable/attached_gun/grenade/proc/prime_grenade(atom/target, obj/item/weapon/gun/gun, mob/living/user)
	set waitfor = FALSE
	var/obj/item/explosive/grenade/grenade = current_rounds[ammo_position]

	if(grenade.antigrief_protection && user.faction == GLOB.faction_datum[FACTION_MARINE] && explosive_antigrief_check(grenade, user))
		to_chat(user, SPAN_WARNING("\The [name]'s safe-area accident inhibitor prevents you from firing!"))
		msg_admin_niche("[key_name(user)] attempted to prime \a [gun.name] in [get_area(src)] [ADMIN_JMP(src.loc)]")
		return

	current_rounds[ammo_position] = "empty"
	ammo_position--

	playsound(user.loc, fire_sound, 50, 1)
	msg_admin_attack("[key_name_admin(user)] fired an underslung grenade launcher [ADMIN_JMP_USER(user)]")
	log_game("[key_name_admin(user)] used an underslung grenade launcher.")

	var/pass_flags = NO_FLAGS
	pass_flags |= grenade_pass_flags
	grenade.det_time = min(15, grenade.det_time)
	grenade.throw_range = max_range
	grenade.activate(user, FALSE)
	grenade.forceMove(get_turf(gun))
	grenade.throw_atom(target, max_range, SPEED_VERY_FAST, user, null, NORMAL_LAUNCH, pass_flags)
	update_ammo_hud(user)
	cocked = FALSE // we have fired so uncock the gun

//For the Mk1
/obj/item/attachable/attached_gun/grenade/mk1
	name = "MK1 underslung grenade launcher"
	desc = "An older version of the classic underslung grenade launcher. Can store five grenades, and fire them farther, but fires them slower."
	icon_state = "grenade-mk1"
	attach_icon = "grenade-mk1_a"
	max_rounds = 5
	max_range = 10
	attachment_firing_delay = 30

/obj/item/attachable/attached_gun/grenade/m203 //M16 GL, only DD have it.
	name = "M203 Grenade Launcher"
	desc = "An antique underbarrel grenade launcher. Adopted in 1969 for the M16, it was made obsolete centuries ago; how its ended up here is a mystery to you. Holds only one propriatary 40mm grenade, does not have modern IFF systems, it won't pass through your friends."
	icon_state = "grenade-m203"
	attach_icon = "grenade-m203_a"
	current_rounds = 0
	max_rounds = 1
	max_range = 14
	attachment_firing_delay = 5 //one shot, so if you can reload fast you can shoot fast

/obj/item/attachable/attached_gun/grenade/m203/Initialize()
	. = ..()
	grenade_pass_flags = NO_FLAGS

//"ammo/flamethrower" is a bullet, but the actual process is handled through fire_attachment, linked through Fire().
/obj/item/attachable/attached_gun/flamer
	name = "mini flamethrower"
	icon_state = "flamethrower"
	attach_icon = "flamethrower_a"
	desc = "A weapon-mounted refillable flamethrower attachment. It has a secondary setting for a more intense flame with far less propulsion ability and heavy fuel usage."
	w_class = SIZE_MEDIUM
	ammo = /datum/ammo/flamethrower
	ammo_position = 40
	max_rounds = 40
	max_range = 5
	spawn_empty = FALSE
	slot = "under"
	fire_sound = 'sound/weapons/gun_flamethrower3.ogg'
	gun_activate_sound = 'sound/weapons/handling/gun_underbarrel_flamer_activate.ogg'
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION|ATTACH_RELOADABLE|ATTACH_WEAPON
	var/burn_level = BURN_LEVEL_TIER_1
	var/burn_duration = BURN_TIME_TIER_1
	var/round_usage_per_tile = 1
	var/intense_mode = FALSE

/obj/item/attachable/attached_gun/flamer/New()
	..()
	attachment_firing_delay = FIRE_DELAY_TIER_4 * 5

/obj/item/attachable/attached_gun/flamer/get_examine_text(mob/user)
	. = ..()
	if(intense_mode)
		. += "It is currently using a more intense and volatile flame."
	else
		. += "It is using a normal and stable flame."
	if(ammo_position)
		. += "It has [ammo_position] unit\s of fuel left."
	else
		. += "It's empty."

/obj/item/attachable/attached_gun/flamer/unique_action(mob/user)
	..()
	playsound(user,'sound/weapons/handling/flamer_ignition.ogg', 25, 1)
	if(intense_mode)
		to_chat(user, SPAN_WARNING("You change \the [src] back to using a normal and more stable flame."))
		round_usage_per_tile = 1
		burn_level = BURN_LEVEL_TIER_1
		burn_duration = BURN_TIME_TIER_1
		max_range = 5
		intense_mode = FALSE
	else
		to_chat(user, SPAN_WARNING("You change \the [src] to use a more intense and volatile flame."))
		round_usage_per_tile = 5
		burn_level = BURN_LEVEL_TIER_5
		burn_duration = BURN_TIME_TIER_2
		max_range = 2
		intense_mode = TRUE

/obj/item/attachable/attached_gun/flamer/handle_pre_break_attachment_description(base_description_text as text)
	return base_description_text + " It is on [intense_mode ? "intense" : "normal"] mode."

/obj/item/attachable/attached_gun/flamer/get_attachment_ammo_type()
	return list("flame", "flame_empty")

/obj/item/attachable/attached_gun/flamer/get_attachment_ammo_count()
	return round(100 * ammo_position/max_rounds)

/obj/item/attachable/attached_gun/flamer/reload_attachment(obj/item/ammo_magazine/flamer_tank/FT, mob/user)
	if(istype(FT))
		if(ammo_position >= max_rounds)
			to_chat(user, SPAN_WARNING("[src] is full."))
		else if(FT.ammo_position <= 0)
			to_chat(user, SPAN_WARNING("[FT] is empty!"))
		else
			playsound(user, 'sound/effects/refill.ogg', 25, 1, 3)
			to_chat(user, SPAN_NOTICE("You refill [src] with [FT]."))
			var/transfered_rounds = min(max_rounds - ammo_position, FT.ammo_position)

			for(var/i=0;i<transfered_rounds;i++)
				var/obj/item/projectile/projectile = FT.transfer_bullet_out()
				projectile.forceMove(src)
				ammo_position++
				current_rounds[ammo_position] = projectile

			var/amount_of_reagents = FT.reagents.reagent_list.len
			var/amount_removed_per_reagent = transfered_rounds / amount_of_reagents
			for(var/datum/reagent/R in FT.reagents.reagent_list)
				R.volume -= amount_removed_per_reagent
			FT.update_icon()
			update_ammo_hud(user)
	else
		to_chat(user, SPAN_WARNING("[src] can only be refilled with an incinerator tank."))

/obj/item/attachable/attached_gun/flamer/fire_attachment(atom/target, obj/item/weapon/gun/gun, mob/living/user)
	if(get_dist(user,target) > max_range+4)
		to_chat(user, SPAN_WARNING("Too far to fire the attachment!"))
		return

	if(!istype(loc, /obj/item/weapon/gun))
		to_chat(user, SPAN_WARNING("\The [src] must be attached to a gun!"))
		return

	var/obj/item/weapon/gun/attached_gun = loc

	if(!(attached_gun.flags_item & WIELDED))
		to_chat(user, SPAN_WARNING("You must wield \the [attached_gun] to fire \the [src]!"))
		return

	if(ammo_position > round_usage_per_tile && ..())
		unleash_flame(target, user)
		if(attached_gun.last_fired < world.time)
			attached_gun.last_fired = world.time

/obj/item/attachable/attached_gun/flamer/proc/unleash_flame(atom/target, mob/living/user)
	set waitfor = FALSE
	var/list/turf/turfs = getline2(user,target)
	var/distance = 0
	var/turf/prev_T
	var/stop_at_turf = FALSE
	playsound(user, 'sound/weapons/gun_flamethrower2.ogg', 50, 1)
	for(var/turf/T in turfs)
		if(T == user.loc)
			prev_T = T
			continue
		if(ammo_position < round_usage_per_tile)
			break
		if(distance >= max_range)
			break

		for(var/i = ammo_position to ammo_position - round_usage_per_tile)
			var/obj/item/projectile/projectile = current_rounds[i]
			current_rounds[ammo_position] = "empty"
			ammo_position--
			qdel(projectile)//we don't use here bullets or etc.
		var/datum/cause_data/cause_data = create_cause_data(initial(name), user)
		if(T.density)
			T.flamer_fire_act(0, cause_data)
			stop_at_turf = TRUE
		else if(prev_T)
			var/atom/movable/temp = new/obj/flamer_fire()
			var/atom/movable/AM = LinkBlocked(temp, prev_T, T)
			qdel(temp)
			if(AM)
				AM.flamer_fire_act(0, cause_data)
				if(AM.flags_atom & ON_BORDER)
					break
				stop_at_turf = TRUE
		flame_turf(T, user)
		if(stop_at_turf)
			break
		distance++
		prev_T = T
		sleep(1)

	show_percentage(user)

/obj/item/attachable/attached_gun/flamer/proc/show_percentage(mob/living/user)
	to_chat(user, SPAN_WARNING("The gauge reads: <b>[round(100 * ammo_position/max_rounds)]</b>% fuel remains!"))
	update_ammo_hud(user)

/obj/item/attachable/attached_gun/flamer/proc/flame_turf(turf/T, mob/living/user)
	if(!istype(T)) return

	if(!locate(/obj/flamer_fire) in T) // No stacking flames!
		var/datum/reagent/napalm/ut/R = new()

		R.intensityfire = burn_level
		R.durationfire = burn_duration

		new/obj/flamer_fire(T, create_cause_data(initial(name), user), R)

/obj/item/attachable/attached_gun/flamer/advanced
	name = "advanced mini flamethrower"
	current_rounds = 50
	max_rounds = 50
	max_range = 6
	burn_level = BURN_LEVEL_TIER_5
	burn_duration = BURN_TIME_TIER_2

/obj/item/attachable/attached_gun/flamer/advanced/integrated
	name = "integrated flamethrower"

/obj/item/attachable/attached_gun/shotgun //basically, a masterkey
	name = "U7 underbarrel shotgun"
	icon_state = "masterkey"
	attach_icon = "masterkey_a"
	desc = "An ARMAT U7 tactical shotgun. Attaches to the underbarrel of most weapons. Only capable of loading up to five buckshot shells. Specialized for breaching into buildings."
	w_class = SIZE_MEDIUM
	max_rounds = 5
	ammo = /datum/ammo/bullet/shotgun/buckshot/masterkey
	caliber = CALIBER_12G
	spawn_empty = FALSE
	slot = "under"
	fire_sound = 'sound/weapons/gun_shotgun_u7.ogg'
	gun_activate_sound = 'sound/weapons/handling/gun_u7_activate.ogg'
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION|ATTACH_PROJECTILE|ATTACH_RELOADABLE|ATTACH_WEAPON

/obj/item/attachable/attached_gun/shotgun/New()
	..()
	attachment_firing_delay = FIRE_DELAY_TIER_5*3

/obj/item/attachable/attached_gun/shotgun/get_examine_text(mob/user)
	. = ..()
	if(ammo_position) 	. += "It has [ammo_position] shell\s left."
	else 					. += "It's empty."

/obj/item/attachable/attached_gun/shotgun/get_attachment_ammo_type()
	if(ammo_position)
		return list(current_rounds[ammo_position].ammo.hud_state, current_rounds[ammo_position].ammo.hud_state_empty)
	else
		return list(ammo.hud_state, ammo.hud_state_empty)

/obj/item/attachable/attached_gun/shotgun/get_attachment_ammo_count()
	return ammo_position

/obj/item/attachable/attached_gun/shotgun/set_bullet_traits()
	LAZYADD(traits_to_give_attached, list(
		BULLET_TRAIT_ENTRY_ID("turfs", /datum/element/bullet_trait_damage_boost, 5, GLOB.damage_boost_turfs),
		BULLET_TRAIT_ENTRY_ID("breaching", /datum/element/bullet_trait_damage_boost, 10.8, GLOB.damage_boost_breaching),
		BULLET_TRAIT_ENTRY_ID("pylons", /datum/element/bullet_trait_damage_boost, 5, GLOB.damage_boost_pylons)
	))

/obj/item/attachable/attached_gun/shotgun/reload_attachment(obj/item/ammo_magazine/handful/mag, mob/user)
	if(istype(mag) && mag.flags_magazine & AMMUNITION_HANDFUL)
		if(mag.caliber[1] == caliber[1])
			if(ammo_position >= max_rounds)
				to_chat(user, SPAN_WARNING("[src] уже заряжен."))
				return FALSE
			else
				var/obj/item/projectile/projectile = mag.transfer_bullet_out()
				projectile.forceMove(src)
				ammo_position++
				current_rounds[ammo_position] = projectile
				mag.update_icon()
				to_chat(user, SPAN_NOTICE("Вы загружаете один патрон в [src]."))
				playsound(user, 'sound/weapons/gun_shotgun_shell_insert.ogg', 25, 1)
				if(mag.ammo_position <= 0)
					user.temp_drop_inv_item(mag)
					qdel(mag)
				update_ammo_hud(user)
				return TRUE
	to_chat(user, SPAN_WARNING("[src] only accepts shotgun ammo [caliber[1]]."))
	return FALSE

/obj/item/attachable/attached_gun/extinguisher
	name = "HME-12 underbarrel extinguisher"
	icon_state = "extinguisher"
	attach_icon = "extinguisher_a"
	desc = "A Taiho-Technologies HME-12 underbarrel extinguisher. Attaches to the underbarrel of most weapons. Point at flame before applying pressure."
	w_class = SIZE_MEDIUM
	slot = "under"
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION|ATTACH_WEAPON|ATTACH_MELEE
	var/obj/item/tool/extinguisher/internal_extinguisher
	ammo_position = 1 //This has to be done to pass the fire_attachment check.

/obj/item/attachable/attached_gun/extinguisher/get_examine_text(mob/user)
	. = ..()
	if(internal_extinguisher)
		. += SPAN_NOTICE("It has [internal_extinguisher.reagents.total_volume] unit\s of water left!")
		return
	. += SPAN_WARNING("It's empty.")

/obj/item/attachable/attached_gun/extinguisher/handle_attachment_description(slot)
	return "It has a [icon2html(src)] [name] ([internal_extinguisher.reagents.total_volume]/[internal_extinguisher.max_water]) mounted underneath.<br>"

/obj/item/attachable/attached_gun/extinguisher/get_attachment_ammo_type()
	return list("flame_blue", "flame_empty") //placeholder

/obj/item/attachable/attached_gun/extinguisher/get_attachment_ammo_count()
	return round(100 * internal_extinguisher.reagents.total_volume/internal_extinguisher.max_water)

/obj/item/attachable/attached_gun/extinguisher/New()
	..()
	initialize_internal_extinguisher()

/obj/item/attachable/attached_gun/extinguisher/fire_attachment(atom/target, obj/item/weapon/gun/gun, mob/living/user)
	if(!internal_extinguisher)
		return
	if(..())
		. = internal_extinguisher.afterattack(target, user)
		update_ammo_hud(user)
		return internal_extinguisher.afterattack(target, user)

/obj/item/attachable/attached_gun/extinguisher/proc/initialize_internal_extinguisher()
	internal_extinguisher = new /obj/item/tool/extinguisher/mini/integrated_flamer()
	internal_extinguisher.safety = FALSE
	internal_extinguisher.create_reagents(internal_extinguisher.max_water)
	internal_extinguisher.reagents.add_reagent("water", internal_extinguisher.max_water)

/obj/item/attachable/attached_gun/extinguisher/pyro
	name = "HME-88B underbarrel extinguisher"
	desc = "An experimental Taiho-Technologies HME-88B underbarrel extinguisher integrated with a select few gun models. It is capable of putting out the strongest of flames. Point at flame before applying pressure."
	flags_attach_features = ATTACH_ACTIVATION|ATTACH_WEAPON|ATTACH_MELEE //not removable

/obj/item/attachable/attached_gun/extinguisher/pyro/initialize_internal_extinguisher()
	internal_extinguisher = new /obj/item/tool/extinguisher/pyro()
	internal_extinguisher.safety = FALSE
	internal_extinguisher.create_reagents(internal_extinguisher.max_water)
	internal_extinguisher.reagents.add_reagent("water", internal_extinguisher.max_water)

/obj/item/attachable/attached_gun/flamer_nozzle
	name = "XM-VESG-1 flamer nozzle"
	desc = "A special nozzle designed to alter flamethrowers to be used in a more offense orientated manner. As the inside of the nozzle is coated in a special gel and resin substance that takes the fuel that passes through and hardens it. Upon exiting the barrel, a cluster of burning gel is projected instead of a stream of burning naphtha."
	desc_lore = "The Experimental Volatile-Exothermic-Sphere-Generator clip-on nozzle attachment for the M240A1 incinerator unit was specifically designed to allow marines to launch fireballs into enemy foxholes and bunkers. Despite the gel and resin coating, the flaming ball of naptha tears apart due the drag caused by launching it through the air, leading marines to use the attachment as a makeshift firework launcher during shore leave."
	icon_state = "flamer_nozzle"
	attach_icon = "flamer_nozzle_a_1"
	w_class = SIZE_MEDIUM
	slot = "under"
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION|ATTACH_WEAPON|ATTACH_MELEE
	pixel_shift_x = 4
	pixel_shift_y = 14

	max_range = 6
	last_fired = 0
	attachment_firing_delay = 2 SECONDS

	var/projectile_type = /datum/ammo/flamethrower
	var/fuel_per_projectile = 3

	var/static/list/fire_sounds = list(
		'sound/weapons/gun_flamethrower1.ogg',
		'sound/weapons/gun_flamethrower2.ogg',
		'sound/weapons/gun_flamethrower3.ogg'
	)

/obj/item/attachable/attached_gun/flamer_nozzle/handle_attachment_description(slot)
	return "It has a [icon2html(src)] [name] mounted beneath the barrel.<br>"

/obj/item/attachable/attached_gun/flamer_nozzle/activate_attachment(obj/item/weapon/gun/gun, mob/living/user, turn_off)
	. = ..()
	attach_icon = "flamer_nozzle_a_[gun.active_attachable == src ? 0 : 1]"
	gun.update_icon()

/obj/item/attachable/attached_gun/flamer_nozzle/fire_attachment(atom/target, obj/item/weapon/gun/gun, mob/living/user)
	. = ..()

	if(world.time < gun.last_fired + gun.fire_delay)
		return

	if((gun.flags_gun_features & GUN_WIELDED_FIRING_ONLY) && !(gun.flags_item & WIELDED))
		to_chat(user, SPAN_WARNING("You need a more secure grip to fire this weapon!"))
		return

	if(gun.flags_gun_features & GUN_TRIGGER_SAFETY)
		to_chat(user, SPAN_WARNING("\The [gun] isn't lit!"))
		return

	if(!istype(gun.current_mag, /obj/item/ammo_magazine/flamer_tank))
		to_chat(user, SPAN_WARNING("\The [gun] needs a flamer tank installed!"))
		return

	if(!length(gun.current_mag.reagents.reagent_list))
		to_chat(user, SPAN_WARNING("\The [gun] doesn't have enough fuel to launch a projectile!"))
		return

	var/datum/reagent/flamer_reagent = gun.current_mag.reagents.reagent_list[1]
	if(flamer_reagent.volume < FLAME_REAGENT_USE_AMOUNT * fuel_per_projectile)
		to_chat(user, SPAN_WARNING("\The [gun] doesn't have enough fuel to launch a projectile!"))
		return

	gun.last_fired = world.time
	gun.current_mag.reagents.remove_reagent(flamer_reagent.id, FLAME_REAGENT_USE_AMOUNT * fuel_per_projectile)

	var/obj/item/projectile/proj = new(src, create_cause_data(initial(name), user, src))
	var/datum/ammo/flamethrower/ammo_datum = new projectile_type
	ammo_datum.flamer_reagent_type = flamer_reagent.type
	proj.generate_bullet(ammo_datum)
	proj.icon_state = "naptha_ball"
	proj.color = flamer_reagent.color
	proj.fire_at(target, user, user, max_range, AMMO_SPEED_TIER_2, null)
	var/turf/user_turf = get_turf(user)
	playsound(user_turf, pick(fire_sounds), 50, TRUE)

	to_chat(user, SPAN_WARNING("The gauge reads: <b>[round(gun.current_mag.get_ammo_percent())]</b>% fuel remaining!"))

/obj/item/attachable/verticalgrip
	name = "vertical grip"
	desc = "A vertical foregrip that offers better accuracy, less recoil, and less scatter, especially during burst fire. \nHowever, it also increases weapon size."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "verticalgrip"
	attach_icon = "verticalgrip_a"
	size_mod = 1
	slot = "under"
	pixel_shift_x = 20

/obj/item/attachable/verticalgrip/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_3
	recoil_mod = -RECOIL_AMOUNT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	burst_scatter_mod = -2
	movement_onehanded_acc_penalty_mod = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_3
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_10


/obj/item/attachable/angledgrip
	name = "angled grip"
	desc = "An angled foregrip that improves weapon ergonomics and offers less recoil, and faster wielding time. \nHowever, it also increases weapon size."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "angledgrip"
	attach_icon = "angledgrip_a"
	wield_delay_mod = -WIELD_DELAY_FAST
	size_mod = 1
	slot = "under"
	pixel_shift_x = 20

/obj/item/attachable/angledgrip/New()
	..()
	recoil_mod = -RECOIL_AMOUNT_TIER_4
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_1
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	scatter_unwielded_mod = SCATTER_AMOUNT_TIER_10



/obj/item/attachable/gyro
	name = "gyroscopic stabilizer"
	desc = "A set of weights and balances to stabilize the weapon when fired with one hand. Slightly decreases firing speed."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "gyro"
	attach_icon = "gyro_a"
	slot = "under"

/obj/item/attachable/gyro/New()
	..()
	delay_mod = FIRE_DELAY_TIER_9
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	burst_scatter_mod = -2
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_3
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_6
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_3

/obj/item/attachable/gyro/Attach(obj/item/weapon/gun/gun)
	if(istype(gun, /obj/item/weapon/gun/shotgun))
		accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_10 + HIT_ACCURACY_MULT_TIER_1
	else
		accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_3
	..()


/obj/item/attachable/lasersight
	name = "laser sight"
	desc = "A laser sight that attaches to the underside of most weapons. Increases accuracy and decreases scatter, especially while one-handed."
	desc_lore = "A standard visible-band laser module designated as the AN/PEQ-42 Laser Sight. Can be mounted onto any firearm that has a lower rail large enough to accommodate it."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "lasersight"
	attach_icon = "lasersight_a"
	slot = "under"
	pixel_shift_x = 17
	pixel_shift_y = 17

/obj/item/attachable/lasersight/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_1
	movement_onehanded_acc_penalty_mod = -MOVEMENT_ACCURACY_PENALTY_MULT_TIER_5
	scatter_mod = -SCATTER_AMOUNT_TIER_10
	scatter_unwielded_mod = -SCATTER_AMOUNT_TIER_9
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_1


/obj/item/attachable/bipod
	name = "bipod"
	desc = "A simple set of telescopic poles to keep a weapon stabilized during firing. \nGreatly increases accuracy and reduces recoil when properly placed, but also increases weapon size and slows firing speed."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "bipod"
	attach_icon = "bipod_a"
	slot = "under"
	size_mod = 2
	melee_mod = -10
	flags_attach_features = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle
	var/initial_mob_dir = NORTH // the dir the mob faces the moment it deploys the bipod
	var/bipod_deployed = FALSE

/obj/item/attachable/bipod/New()
	..()

	delay_mod = FIRE_DELAY_TIER_9
	wield_delay_mod = WIELD_DELAY_FAST
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_5
	scatter_mod = SCATTER_AMOUNT_TIER_9
	recoil_mod = RECOIL_AMOUNT_TIER_5

/obj/item/attachable/bipod/Attach(obj/item/weapon/gun/gun)
	..()

	RegisterSignal(gun, COMSIG_ITEM_DROPPED, PROC_REF(handle_drop))

/obj/item/attachable/bipod/Detach(mob/user, obj/item/weapon/gun/detaching_gub)
	UnregisterSignal(detaching_gub, COMSIG_ITEM_DROPPED)

	if(bipod_deployed)
		undeploy_bipod(detaching_gub)
	..()

/obj/item/attachable/bipod/update_icon()
	if(bipod_deployed)
		icon_state = "[icon_state]-on"
		attach_icon = "[attach_icon]-on"
	else
		icon_state = initial(icon_state)
		attach_icon = initial(attach_icon)

	if(istype(loc, /obj/item/weapon/gun))
		var/obj/item/weapon/gun/gun = loc
		gun.update_attachable(slot)
		for(var/datum/action/action as anything in gun.actions)
			action.update_button_icon()

/obj/item/attachable/bipod/proc/handle_drop(obj/item/weapon/gun/gun, mob/living/carbon/human/user)
	SIGNAL_HANDLER

	UnregisterSignal(user, COMSIG_MOB_MOVE_OR_LOOK)

	if(bipod_deployed)
		undeploy_bipod(gun)
		user.apply_effect(1, SUPERSLOW)
		user.apply_effect(2, SLOW)

/obj/item/attachable/bipod/proc/undeploy_bipod(obj/item/weapon/gun/gun)
	bipod_deployed = FALSE
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_5
	scatter_mod = SCATTER_AMOUNT_TIER_9
	recoil_mod = RECOIL_AMOUNT_TIER_5
	burst_scatter_mod = 0
	delay_mod = FIRE_DELAY_TIER_10
	gun.recalculate_attachment_bonuses()
	var/mob/living/user
	if(isliving(gun.loc))
		user = gun.loc
		UnregisterSignal(user, COMSIG_MOB_MOVE_OR_LOOK)

	if(gun.flags_gun_features & GUN_SUPPORT_PLATFORM)
		gun.remove_bullet_trait("iff")

	if(!QDELETED(gun))
		playsound(user,'sound/items/m56dauto_rotate.ogg', 55, 1)
		update_icon()

/obj/item/attachable/bipod/activate_attachment(obj/item/weapon/gun/gun,mob/living/user, turn_off)
	if(turn_off)
		if(bipod_deployed)
			undeploy_bipod(gun)
	else
		var/obj/support = check_bipod_support(gun, user)
		if(!support&&!bipod_deployed)
			to_chat(user, SPAN_NOTICE("You start deploying [src] on the ground."))
			if(!do_after(user, 15, INTERRUPT_ALL, BUSY_ICON_HOSTILE, gun,INTERRUPT_DIFF_LOC))
				return FALSE

		bipod_deployed = !bipod_deployed
		if(user)
			if(bipod_deployed)
				to_chat(user, SPAN_NOTICE("You deploy [src] [support ? "on [support]" : "on the ground"]."))
				playsound(user,'sound/items/m56dauto_rotate.ogg', 55, 1)
				accuracy_mod = HIT_ACCURACY_MULT_TIER_5
				scatter_mod = -SCATTER_AMOUNT_TIER_10
				recoil_mod = -RECOIL_AMOUNT_TIER_4
				burst_scatter_mod = -SCATTER_AMOUNT_TIER_8
				if(istype(gun,/obj/item/weapon/gun/rifle/sniper/M42A))
					delay_mod = -FIRE_DELAY_TIER_7
				else
					delay_mod = -FIRE_DELAY_TIER_10
				gun.recalculate_attachment_bonuses()

				initial_mob_dir = user.dir
				RegisterSignal(user, COMSIG_MOB_MOVE_OR_LOOK, PROC_REF(handle_mob_move_or_look))

				if(gun.flags_gun_features & GUN_SUPPORT_PLATFORM)
					gun.add_bullet_trait(BULLET_TRAIT_ENTRY_ID("iff", /datum/element/bullet_trait_iff))

			else
				to_chat(user, SPAN_NOTICE("You retract [src]."))
				undeploy_bipod(gun)

	update_icon()

	return 1

/obj/item/attachable/bipod/proc/handle_mob_move_or_look(mob/living/mover, actually_moving, direction, specific_direction)
	SIGNAL_HANDLER

	if(!actually_moving && (specific_direction & initial_mob_dir)) // if you're facing north, but you're shooting north-east and end up facing east, you won't lose your bipod
		return
	undeploy_bipod(loc, mover)
	mover.apply_effect(1, SUPERSLOW)
	mover.apply_effect(2, SLOW)


//when user fires the gun, we check if they have something to support the gun's bipod.
/obj/item/attachable/proc/check_bipod_support(obj/item/weapon/gun/gun, mob/living/user)
	return 0

/obj/item/attachable/bipod/check_bipod_support(obj/item/weapon/gun/gun, mob/living/user)
	var/turf/T = get_turf(user)
	for(var/obj/O in T)
		if(O.throwpass && O.density && O.dir == user.dir && O.flags_atom & ON_BORDER)
			return O
	var/turf/T2 = get_step(T, user.dir)

	for(var/obj/O2 in T2)
		if(O2.throwpass && O2.density)
			return O2
	return 0


/obj/item/attachable/bipod/m60
	name = "bipod"
	desc = "A simple set of telescopic poles to keep a weapon stabilized during firing. This one looks rather old.\nGreatly increases accuracy and reduces recoil when properly placed, but also increases weapon size and slows firing speed."
	icon_state = "bipod_m60"
	attach_icon = "bipod_m60_a"

	flags_attach_features = ATTACH_ACTIVATION


/obj/item/attachable/burstfire_assembly
	name = "burst fire assembly"
	desc = "A small angled piece of fine machinery that increases the burst count on some weapons, and grants the ability to others. \nIncreases weapon scatter."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "rapidfire"
	attach_icon = "rapidfire_a"
	slot = "under"

/obj/item/attachable/burstfire_assembly/New()
	..()
	accuracy_mod = -HIT_ACCURACY_MULT_TIER_3
	burst_mod = BURST_AMOUNT_TIER_2

	accuracy_unwielded_mod = -HIT_ACCURACY_MULT_TIER_4

/obj/item/attachable/eva_doodad
	name = "RXF-M5 EVA beam projector"
	desc = "A strange little doodad that projects an invisible beam that the EVA pistol's actual laser travels in, used as a focus that slightly weakens the laser's intensity. Or at least that's what the manual said."
	icon = 'icons/obj/items/weapons/guns/attachments/under.dmi'
	icon_state = "rxfm5_eva_doodad"
	attach_icon = "rxfm5_eva_doodad_a"
	slot = "under"

/obj/item/attachable/eva_doodad/New()
	..()
	accuracy_mod = HIT_ACCURACY_MULT_TIER_5
	accuracy_unwielded_mod = HIT_ACCURACY_MULT_TIER_5
	damage_mod -= BULLET_DAMAGE_MULT_TIER_4
