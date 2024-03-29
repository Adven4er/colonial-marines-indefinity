
//-------------------------------------------------------
//M4A3 PISTOL

/obj/item/ammo_magazine/pistol
	name = "M4A3 magazine (9mm)"
	desc = "A pistol magazine."
	caliber = CALIBER_9MM
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/uscm.dmi'
	icon_state = "m4a3"
	max_rounds = 12
	w_class = SIZE_SMALL
	ammo_preset = list(/datum/ammo/bullet/pistol)
	gun_type = /obj/item/weapon/gun/pistol/m4a3
	transfer_delay = 0.6 SECONDS
	ammo_band_icon = "+m4a3_band"
	ammo_band_icon_empty = "+m4a3_band_e"

/obj/item/ammo_magazine/pistol/hp
	name = "M4A3 hollowpoint magazine (9mm)"
	desc = "A pistol magazine. This one contains hollowpoint bullets, which have noticeably higher stopping power on unarmored targets, and noticeably less on armored targets."
	ammo_preset = list(/datum/ammo/bullet/pistol/hollow)
	ammo_band_color = AMMO_BAND_COLOR_HOLLOWPOINT

/obj/item/ammo_magazine/pistol/ap
	name = "M4A3 AP magazine (9mm)"
	desc = "A pistol magazine. This one contains armor-piercing bullets, which have noticeably higher stopping power on well-armored targets, and noticeably less on unarmored or lightly-armored targets."
	ammo_preset = list(/datum/ammo/bullet/pistol/ap)
	ammo_band_color = AMMO_BAND_COLOR_AP

/obj/item/ammo_magazine/pistol/rubber
	name = "M4A3 Rubber magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/rubber)
	ammo_band_color = AMMO_BAND_COLOR_RUBBER

/obj/item/ammo_magazine/pistol/incendiary
	name = "M4A3 incendiary magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/incendiary)
	ammo_band_color = AMMO_BAND_COLOR_INCENDIARY

/obj/item/ammo_magazine/pistol/penetrating
	name = "M4A3 wall-piercing magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap/penetrating)
	ammo_band_color = AMMO_BAND_COLOR_PENETRATING

/obj/item/ammo_magazine/pistol/cluster
	name = "M4A3 cluster magazine (9mm)"
	desc = "A pistol magazine. Designed to attach tiny explosives to targets, to detonate all at once if enough hit."
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy/cluster)
	ammo_band_color = AMMO_BAND_COLOR_CLUSTER

/obj/item/ammo_magazine/pistol/toxin
	name = "M4A3 toxin magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap/toxin)
	ammo_band_color = AMMO_BAND_COLOR_TOXIN

//-------------------------------------------------------
//M4A3 45 //Inspired by the 1911

/obj/item/ammo_magazine/pistol/m1911
	name = "M1911 magazine (.45)"
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy)
	caliber = CALIBER_45
	icon_state = "m4a345"//rename later
	max_rounds = 7
	gun_type = /obj/item/weapon/gun/pistol/m1911


//-------------------------------------------------------
//88M4 based off VP70

/obj/item/ammo_magazine/pistol/mod88
	name = "88M4 AP magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap)
	caliber = CALIBER_9MM
	icon_state = "88m4"
	max_rounds = 19
	gun_type = /obj/item/weapon/gun/pistol/mod88
	ammo_band_icon = "+88m4_band"
	ammo_band_icon_empty = "+88m4_band_e"
	ammo_band_color = AMMO_BAND_COLOR_AP

/obj/item/ammo_magazine/pistol/mod88/normalpoint // Unused
	name = "88M4 FMJ magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol)
	caliber = "9mm"
	ammo_band_color = null

/obj/item/ammo_magazine/pistol/mod88/normalpoint/extended // Unused
	name = "88M4 FMJ extended magazine (9mm)"
	icon_state = "88m4_mag_ex"
	ammo_preset = list(/datum/ammo/bullet/pistol)
	caliber = "9mm"

/obj/item/ammo_magazine/pistol/mod88/toxin
	name = "88M4 toxic magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap/toxin)
	ammo_band_color = AMMO_BAND_COLOR_TOXIN

/obj/item/ammo_magazine/pistol/mod88/penetrating
	name = "88M4 wall-piercing magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap/penetrating)
	ammo_band_color = AMMO_BAND_COLOR_PENETRATING

/obj/item/ammo_magazine/pistol/mod88/cluster
	name = "88M4 cluster magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/ap/cluster)
	ammo_band_color = AMMO_BAND_COLOR_CLUSTER

/obj/item/ammo_magazine/pistol/mod88/incendiary
	name = "88M4 incendiary magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/incendiary)
	ammo_band_color = AMMO_BAND_COLOR_INCENDIARY

/obj/item/ammo_magazine/pistol/mod88/rubber
	name = "88M4 rubber magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/rubber)
	ammo_band_color = AMMO_BAND_COLOR_RUBBER


//-------------------------------------------------------
//ES-4

/obj/item/ammo_magazine/pistol/es4
	name = "ES-4 stun magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/rubber/stun)
	caliber = "9mm"
	desc = "Holds 19 rounds of specialized Conductive 9mm. Electrostatic propulsion in the ES-4 functions by propelling an cV9mm round, at a proportionally slower velocity to maintain a higher kinetic energy transfer rate. All this turns a penetrative round into a less-than-lethal round."
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/wy.dmi'
	icon_state = "es4"
	max_rounds = 19
	gun_type = /obj/item/weapon/gun/pistol/es4

//-------------------------------------------------------
//VP78

/obj/item/ammo_magazine/pistol/vp78
	name = "VP78 magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash)
	caliber = CALIBER_9MM
	icon_state = "vp78" //PLACEHOLDER
	max_rounds = 18
	gun_type = /obj/item/weapon/gun/pistol/vp78
	ammo_band_icon = "+vp78_band"
	ammo_band_icon_empty = "+vp78_band_e"

/obj/item/ammo_magazine/pistol/vp78/toxin
	name = "VP78 toxic magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash/toxin)
	ammo_band_color = AMMO_BAND_COLOR_TOXIN

/obj/item/ammo_magazine/pistol/vp78/penetrating
	name = "VP78 wall-piercing magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash/penetrating)
	ammo_band_color = AMMO_BAND_COLOR_PENETRATING

/obj/item/ammo_magazine/pistol/vp78/cluster
	name = "VP78 cluster magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash/cluster)
	ammo_band_color = AMMO_BAND_COLOR_CLUSTER

/obj/item/ammo_magazine/pistol/vp78/incendiary
	name = "VP78 incendiary magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash/incendiary)
	ammo_band_color = AMMO_BAND_COLOR_INCENDIARY


//-------------------------------------------------------
//Beretta 92FS, the gun McClane carries around in Die Hard. Very similar to the service pistol, all around.

/obj/item/ammo_magazine/pistol/b92fs
	name = "Beretta 92FS magazine (9mm)"
	caliber = CALIBER_9MM
	icon_state = "m4a3" //PLACEHOLDER
	max_rounds = 15
	ammo_preset = list(/datum/ammo/bullet/pistol)
	gun_type = /obj/item/weapon/gun/pistol/b92fs


//-------------------------------------------------------
//DEAGLE //This one is obvious.

/obj/item/ammo_magazine/pistol/heavy
	name = "Desert Eagle magazine (.50)"
	ammo_preset = list(/datum/ammo/bullet/pistol/deagle)
	caliber = CALIBER_50
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/colony.dmi'
	icon_state = "deagle"
	max_rounds = 7
	gun_type = /obj/item/weapon/gun/pistol/heavy
	ammo_band_icon = "+deagle_band"
	ammo_band_icon_empty = "+deagle_band_e"

/obj/item/ammo_magazine/pistol/heavy/super //Commander's variant
	name = "Heavy Desert Eagle magazine (.50)"
	desc = "Seven rounds of devastatingly powerful 50-caliber destruction."
	gun_type = /obj/item/weapon/gun/pistol/heavy/co
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy/super)
	ammo_band_color = AMMO_BAND_COLOR_SUPER

/obj/item/ammo_magazine/pistol/heavy/super/highimpact
	name = "High Impact Desert Eagle magazine (.50)"
	desc = "Seven rounds of devastatingly powerful 50-caliber destruction. The bullets are tipped with a synthesized osmium and lead alloy to stagger absolutely anything they hit. Point away from anything you value."
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy/super/highimpact)
	ammo_band_color = AMMO_BAND_COLOR_HIGH_IMPACT

/obj/item/ammo_magazine/pistol/heavy/super/highimpact/ap
	name = "High Impact Armor-Piercing Desert Eagle magazine (.50)"
	desc = "Seven rounds of devastatingly powerful 50-caliber destruction. Packs a devastating punch. The bullets are tipped with an osmium-tungsten carbide alloy to not only stagger but shred through any target's armor. Issued in few numbers due to the massive production cost and worries about hull breaches. Point away from anything you value."
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy/super/highimpact/ap)
	ammo_band_color = AMMO_BAND_COLOR_AP

//-------------------------------------------------------
//Type 31 pistol. //A makarov

/obj/item/ammo_magazine/pistol/np92
	name = "NP92 magazine (9x18mm Makarov)"
	ammo_preset = list(/datum/ammo/bullet/pistol)
	caliber = CALIBER_9MM
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/upp.dmi'
	icon_state = "np92mag"
	max_rounds = 12
	gun_type = /obj/item/weapon/gun/pistol/np92

/obj/item/ammo_magazine/pistol/np92/suppressed
	name = "NPZ92 magazine (9x18mm Makarov)"
	ammo_preset = list(/datum/ammo/bullet/pistol)
	caliber = CALIBER_9MM
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/upp.dmi'
	icon_state = "npz92mag"
	max_rounds = 12

/obj/item/ammo_magazine/pistol/np92/tranq
	name = "NPZ92 tranq magazine (9x18mm Makarov)"
	ammo_preset = list(/datum/ammo/bullet/pistol/tranq)
	caliber = CALIBER_9MM
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/upp.dmi'
	icon_state = "npz92tranqmag"
	max_rounds = 12

//-------------------------------------------------------
//Type 73 pistol. //A TT

/obj/item/ammo_magazine/pistol/t73
	name = "Type 73 magazine (7.62x25mm Tokarev)"
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy)
	caliber = "7.62x25mm Tokarev"
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/upp.dmi'
	icon_state = "ttmag"
	max_rounds = 9
	gun_type = /obj/item/weapon/gun/pistol/t73

/obj/item/ammo_magazine/pistol/t73_impact
	name = "High Impact Type 74 magazine (7.62x25mm Tokarev)"
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy/super/highimpact/upp)
	caliber = "7.62x25mm Tokarev"
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/upp.dmi'
	icon_state = "ttmag_impact"
	max_rounds = 9
	gun_type = /obj/item/weapon/gun/pistol/t73/leader

//-------------------------------------------------------
//KT-42 //Inspired by the .44 Auto Mag pistol

/obj/item/ammo_magazine/pistol/kt42
	name = "KT-42 magazine (.44)"
	ammo_preset = list(/datum/ammo/bullet/pistol/heavy)
	caliber = CALIBER_44
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/colony.dmi'
	icon_state = "kt42"
	max_rounds = 16
	gun_type = /obj/item/weapon/gun/pistol/kt42

//-------------------------------------------------------
//PIZZACHIMP PROTECTION

/obj/item/ammo_magazine/pistol/holdout
	name = "tiny pistol magazine (.22)"
	desc = "A surprisingly small magazine, holding .22 bullets. No Kolibri, but it's getting there."
	ammo_preset = list(/datum/ammo/bullet/pistol/tiny)
	caliber = CALIBER_22
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/colony.dmi'
	icon_state = "holdout"
	max_rounds = 5
	w_class = SIZE_TINY
	gun_type = /obj/item/weapon/gun/pistol/holdout

//-------------------------------------------------------
//CLF HOLDOUT PISTOL

/obj/item/ammo_magazine/pistol/clfpistol
	name = "D18 magazine (9mm)"
	desc = "A small D18 magazine storing 7 9mm bullets. How is it even this small?"
	ammo_preset = list(/datum/ammo/bullet/pistol)
	caliber = "9mm"
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/uscm.dmi'
	icon_state = "m4a3" // placeholder
	max_rounds = 7
	w_class = SIZE_TINY
	gun_type = /obj/item/weapon/gun/pistol/clfpistol

//-------------------------------------------------------
//.45 MARSHALS PISTOL //Inspired by the Browning Hipower
// rebalanced - singlefire, very strong bullets but slow to fire and heavy recoil
// redesigned - now rejected USCM sidearm model, utilized by Colonial Marshals and other stray groups.

/obj/item/ammo_magazine/pistol/highpower
	name = "MK-45 Automagnum magazine (.45)"
	ammo_preset = list(/datum/ammo/bullet/pistol/highpower)
	caliber = CALIBER_45
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/colony.dmi'
	icon_state = "highpower"
	max_rounds = 13
	gun_type = /obj/item/weapon/gun/pistol/highpower

//comes in black, for the black variant of the highpower, better for military usage

/obj/item/ammo_magazine/pistol/highpower/black
	icon_state = "highpower_b"

//-------------------------------------------------------
/*
Auto 9 The gun RoboCop uses. A better version of the VP78, with more rounds per magazine. Probably the best pistol around, but takes no attachments.
It is a modified Beretta 93R, and can fire three-round burst or single fire. Whether or not anyone else aside RoboCop can use it is not established.
*/

/obj/item/ammo_magazine/pistol/auto9
	name = "Auto-9 magazine (9mm)"
	ammo_preset = list(/datum/ammo/bullet/pistol/squash)
	caliber = CALIBER_9MM
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/uscm.dmi'
	icon_state = "88m4" //PLACEHOLDER
	max_rounds = 50
	gun_type = /obj/item/weapon/gun/pistol/auto9



//-------------------------------------------------------
//The first rule of monkey pistol is we don't talk about monkey pistol.
/obj/item/ammo_magazine/pistol/chimp
	name = "CHIMP70 magazine (.70M)"
	ammo_preset = list(/datum/ammo/bullet/pistol/mankey)
	caliber = ".70M"
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/event.dmi'
	icon_state = "c70" //PLACEHOLDER

	matter = list("metal" = 3000)
	max_rounds = 300
	gun_type = /obj/item/weapon/gun/pistol/chimp

//-------------------------------------------------------
//Smartpistol IFF magazine.

/obj/item/ammo_magazine/pistol/smart
	name = "SU-6 Smartpistol magazine (.45)"
	ammo_preset = list(/datum/ammo/bullet/pistol/smart)
	caliber = CALIBER_45
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/uscm.dmi'
	icon_state = "smartpistol"
	max_rounds = 15
	gun_type = /obj/item/weapon/gun/pistol/smart

//-------------------------------------------------------
//SKORPION //Based on the same thing.

/obj/item/ammo_magazine/pistol/skorpion
	name = "CZ-81 20-round magazine (.32ACP)"
	desc = "A .32ACP caliber magazine for the CZ-81."
	caliber = CALIBER_32ACP
	icon = 'icons/obj/items/weapons/guns/ammo_by_faction/colony.dmi'
	icon_state = "skorpion" //PLACEHOLDER
	gun_type = /obj/item/weapon/gun/pistol/skorpion
	max_rounds = 20
