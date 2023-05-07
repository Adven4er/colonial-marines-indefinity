//-------------------------------------------------------
//This gun is very powerful, but also has a kick.

/obj/item/weapon/gun/mounted
	name = "Stationar Weapon"
	desc = "Installing on tripod."
	icon = 'icons/obj/structures/barricades.dmi'
	icon_state = "mounted"
	item_state = "mounted"
	var/base_mounted_state = "mounted"
	var/mounted_state = "mounted"

	w_class = SIZE_HUGE
	force = 1
	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	flags_mounted_gun_features = GUN_MOUNTING|GUN_CAN_OVERRIDE_MOUNTED
	max_durability = WEAPON_DURABILITY_HEAVY
	durability_tier = WEAPON_DAMAGE_SMALL
	gun_category = GUN_CATEGORY_MOUNTED

	var/zooms = 0
	class = 1 //0 - null, 1 - small (can install in 1,2,3 class MD), 2 - medium, 3 - big (likely artilery and BFG)

/obj/item/weapon/gun/mounted/set_gun_config_values()
	..()
	fire_delay = FIRE_DELAY_TIER_7
	burst_amount = BURST_AMOUNT_TIER_5
	burst_delay = FIRE_DELAY_TIER_9
	accuracy_mult = BASE_ACCURACY_MULT + HIT_ACCURACY_MULT_TIER_6
	accuracy_mult_unwielded = BASE_ACCURACY_MULT + HIT_ACCURACY_MULT_TIER_6
	scatter = SCATTER_AMOUNT_TIER_7
	scatter_unwielded = SCATTER_AMOUNT_TIER_7
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil_unwielded = RECOIL_AMOUNT_TIER_5

/obj/item/weapon/gun/mounted/update_icon()
	if(overlays)
		overlays.Cut()
	else
		overlays = list()
	..()
	if(blood_overlay) //need to reapply bloodstain because of the Cut.
		overlays += blood_overlay

	var/new_icon_state = gun_icon
	var/new_mounted_state = base_mounted_state

	if(has_empty_icon && (!current_mag || current_mag.ammo_position <= 0))
		new_icon_state += "_e"
		new_mounted_state += "_e"

	if(has_open_icon && (!current_mag || !current_mag.chamber_closed))
		new_icon_state += "_e"
		new_mounted_state += "_e"

	icon_state = new_icon_state
	mounted_state = new_mounted_state
	update_mag_overlay()
	update_attachables()

/obj/item/weapon/gun/mounted/m56d_gun
	name = "M56D Stationary Heavy Machinegun"
	desc = "M56D Stationary Heavy Machinegun, with IFF system, can installed on tripod."
	icon_state = "M56D_gun"
	item_state = "M56D_gun"
	mounted_state = "M56D"
	base_mounted_state = "M56D"
	fire_sound = 'sound/weapons/gun_rifle.ogg'
	var/iff_enabled = TRUE //Begin with the safety on.
	zooms = 1
	current_mag = /obj/item/ammo_magazine/m56d
	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	flags_mounted_gun_features = GUN_MOUNTING|GUN_CAN_OVERRIDE_MOUNTED

/obj/item/weapon/gun/mounted/m56d_gun/set_bullet_traits()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY_ID("iff", /datum/element/bullet_trait_iff)
	))

/obj/item/weapon/gun/mounted/m56d_gun/proc/toggle_lethal_mode(mob/user)
	to_chat(user, "[icon2html(src, usr)] You [iff_enabled? "<B>disable</b>" : "<B>enable</b>"] the [src.name]'s fire restriction. You will [iff_enabled ? "harm anyone in your way" : "target through IFF"].")
	playsound(loc,'sound/machines/click.ogg', 25, 1)
	iff_enabled = !iff_enabled
	if(iff_enabled)
		add_bullet_trait(BULLET_TRAIT_ENTRY_ID("iff", /datum/element/bullet_trait_iff))
	if(!iff_enabled)
		remove_bullet_trait("iff")


///GRENADE LAUNCHER
/obj/item/weapon/gun/launcher/grenade/mounted
	name = "Stationar Weapon"
	desc = "Installing on tripod."
	icon = 'icons/obj/structures/barricades.dmi'
	icon_state = "mounted"
	item_state = "mounted"
	var/base_mounted_state = "mounted"
	var/mounted_state = "mounted"
	preload = /obj/item/explosive/grenade/incendiary/airburst

	w_class = SIZE_HUGE
	force = 1
	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER|GUN_RECOIL_BUILDUP
	flags_mounted_gun_features = GUN_MOUNTING|GUN_CAN_OVERRIDE_MOUNTED
	gun_category = GUN_CATEGORY_MOUNTED

	var/zooms = 0
	class = 1 //0 - null, 1 - small (can install in 1,2,3 class MD), 2 - medium, 3 - big (likely artilery and BFG)

/obj/item/weapon/gun/launcher/grenade/mounted/update_icon()
	..()
	var/GL_sprite = gun_icon
	var/GL_mounted_sprite = base_mounted_state
	if(!cylinder  || cylinder == 1)
		GL_sprite += "_e"
	else if(GL_has_empty_icon && !length(cylinder.contents))
		GL_sprite += "_e"
		GL_mounted_sprite += "_e"
	if(GL_has_open_icon && open_chamber)
		GL_sprite += "_o"
		GL_mounted_sprite += "_o"

	icon_state = GL_sprite
	mounted_state = GL_mounted_sprite

/obj/item/weapon/gun/launcher/grenade/mounted/sgl2_gun
	name = "SGL2 Stationary Heavy Grenadelauncher"
	desc = "SGL2 Stationary Heavy Grenadelauncher, hard weapon, using in war among UPP, very powerfull weapon."
	icon_state = "SGL2_gun"
	item_state = "SGL2_gun"
	base_mounted_state = "SGL2"
	mounted_state = "SGL2"
	is_lobbing = TRUE
	direct_draw = FALSE
	internal_slots = 12

/obj/item/weapon/gun/launcher/grenade/mounted/sgl2_gun/set_gun_config_values()
	..()
	fire_delay = FIRE_DELAY_TIER_1
	burst_amount = BURST_AMOUNT_TIER_2
	burst_delay = FIRE_DELAY_TIER_4
	accuracy_mult = BASE_ACCURACY_MULT
	accuracy_mult_unwielded = BASE_ACCURACY_MULT
	scatter = SCATTER_AMOUNT_TIER_4
	scatter_unwielded = SCATTER_AMOUNT_TIER_4
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil_unwielded = RECOIL_AMOUNT_TIER_3


///ROCKET LAUNCHER
/obj/item/weapon/gun/launcher/rocket/mounted
	name = "Stationar Weapon"
	desc = "Installing on tripod."
	icon = 'icons/obj/structures/barricades.dmi'
	icon_state = "mounted"
	item_state = "mounted"
	var/base_mounted_state = "mounted"
	var/mounted_state = "mounted"

	w_class = SIZE_HUGE
	force = 1
	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	flags_mounted_gun_features = GUN_MOUNTING|GUN_CAN_OVERRIDE_MOUNTED
	gun_category = GUN_CATEGORY_MOUNTED

	var/zooms = 0
	class = 1 //0 - null, 1 - small (can install in 1,2,3 class MD), 2 - medium, 3 - big (likely artilery and BFG)

/obj/item/weapon/gun/launcher/rocket/mounted/update_icon()
	if(overlays)
		overlays.Cut()
	else
		overlays = list()
	..()
	if(blood_overlay) //need to reapply bloodstain because of the Cut.
		overlays += blood_overlay

	var/new_icon_state = gun_icon
	var/new_mounted_state = base_mounted_state

	if(has_empty_icon && (!current_mag || current_mag.ammo_position <= 0))
		new_icon_state += "_e"
		new_mounted_state += "_e"

	if(has_open_icon && (!current_mag || !current_mag.chamber_closed))
		new_icon_state += "_e"
		new_mounted_state += "_e"

	icon_state = new_icon_state
	mounted_state = new_mounted_state
	update_mag_overlay()
	update_attachables()

/obj/item/weapon/gun/launcher/rocket/mounted/rct_gun
	name = "RCT Stationary Rocket Launcher"
	desc = "RCT Stationary Rocket Launcher, can load all USCM rocket types, expanded range fire and special fragmentation rockets ammo."
	icon_state = "RCT_gun"
	item_state = "RCT_gun"
	base_mounted_state = "RCT"
	mounted_state = "RCT"
	zooms = 1
