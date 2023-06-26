/*
/turf

	/open - all turfs with density = FALSE are turf/open

		/floor - floors are constructed floor as opposed to natural grounds

		/space

		/shuttle - shuttle floors are separated from real floors because they're magic

		/snow - snow is one type of non-floor open turf

	/closed - all turfs with density = TRUE are turf/closed

		/wall - walls are constructed walls as opposed to natural solid turfs

			/r_wall

		/shuttle - shuttle walls are separated from real walls because they're magic, and don't smoothes with walls.

		/ice_rock - ice_rock is one type of non-wall closed turf

*/



/turf
	icon = 'icons/turf/floors/floors.dmi'
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE// Important for interaction with and visualization of openspace.

	var/turf_flags = TURF_MULTIZ
	var/weatherproof = TRUE
	var/weedable = FULLY_WEEDABLE
	var/weather_affectable = TRUE
	var/intact_tile = 1 //used by floors to distinguish floor with/without a floortile(e.g. plating).
	var/can_bloody = TRUE //Can blood spawn on this turf?

	var/list/linked_sectors
	var/list/linked_pylons
	var/obj/effect/alien/weeds/weeds
	var/obj/structure/snow/snow
	var/list/datum/automata_cell/autocells
	var/list/obj/effect/decal/cleanable/cleanables

	var/antipierce = 1

	///Lumcount added by sources other than lighting datum objects, such as the overlay lighting component.
	var/dynamic_lumcount = 0

	///Bool, whether this turf will always be illuminated no matter what area it is in
	var/always_lit = FALSE

	var/tmp/lighting_corners_initialised = FALSE

	///Our lighting object.
	var/tmp/datum/lighting_object/lighting_object
	///Lighting Corner datums.
	var/tmp/datum/lighting_corner/lighting_corner_NE
	var/tmp/datum/lighting_corner/lighting_corner_SE
	var/tmp/datum/lighting_corner/lighting_corner_SW
	var/tmp/datum/lighting_corner/lighting_corner_NW

	///Which directions does this turf block the vision of, taking into account both the turf's opacity and the movable opacity_sources.
	var/directional_opacity = NONE
	///Lazylist of movable atoms providing opacity sources.
	var/list/atom/movable/opacity_sources

	var/list/baseturfs = /turf/baseturf_bottom
	var/changing_turf = FALSE
	var/chemexploded = FALSE // Prevents explosion stacking

	// Fishing
	var/supports_fishing = FALSE // set to false when MRing, this is just for testing

/turf/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE) // this doesn't parent call for optimisation reasons
	if(flags_atom & INITIALIZED)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_atom |= INITIALIZED

	// by default, vis_contents is inherited from the turf that was here before
	vis_contents.Cut()

	turfs += src

	if(length(smoothing_groups))
		sortTim(smoothing_groups) //In case it's not properly ordered, let's avoid duplicate entries with the same values.
		SET_BITFLAG_LIST(smoothing_groups)
	if(length(canSmoothWith))
		sortTim(canSmoothWith)
		if(canSmoothWith[length(canSmoothWith)] > MAX_S_TURF) //If the last element is higher than the maximum turf-only value, then it must scan turf contents for smoothing targets.
			smoothing_flags |= SMOOTH_OBJ
		SET_BITFLAG_LIST(canSmoothWith)
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH(src)

	assemble_baseturfs()

	levelupdate()

	visibilityChanged()

	//Get area light
	var/area/A = loc
	if(A.area_has_base_lighting && always_lit) //Only provide your own lighting if the area doesn't for you
		add_overlay(GLOB.fullbright_overlay)

	if(light_power && light_range)
		update_light()

	multiz_turfs()

	if(opacity)
		directional_opacity = ALL_CARDINALS

	pass_flags = pass_flags_cache[type]
	if(isnull(pass_flags))
		pass_flags = new()
		initialize_pass_flags(pass_flags)
		pass_flags_cache[type] = pass_flags
	else
		initialize_pass_flags()

	for(var/atom/movable/AM in src)
		Entered(AM)

	return INITIALIZE_HINT_NORMAL

/turf/Destroy(force)
	. = QDEL_HINT_IWILLGC
	if(!changing_turf)
		stack_trace("Incorrect turf deletion")
	changing_turf = FALSE
	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_del(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_del(src, UP)
	for(var/cleanable_type in cleanables)
		var/obj/effect/decal/cleanable/C = cleanables[cleanable_type]
		C.cleanup_cleanable()
	if(force)
		..()
		//this will completely wipe turf state
		var/turf/B = new world.turf(src)
		for(var/A in B.contents)
			qdel(A)
		for(var/I in B.vars)
			B.vars[I] = null
		return
	visibilityChanged()
	flags_atom &= ~INITIALIZED
	..()

/turf/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_EXPLODE, "Trigger Explosion")
	VV_DROPDOWN_OPTION(VV_HK_EMPULSE, "Trigger EM Pulse")

/turf/ex_act(severity)
	return 0

/turf/proc/update_icon() //Base parent. - Abby
	return

/turf/proc/multiz_turf_del(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_DEL, T, dir)

/turf/proc/multiz_turf_new(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_NEW, T, dir)

/turf/proc/multiz_turfs()
	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)
		if(turf_flags & TURF_MULTIZ)
			var/list/baseturfsold = list(/turf/open/openspace)
			baseturfsold += baseturfs
			baseturfs = list()
			for(var/i in baseturfsold)
				baseturfs += i

/turf/proc/add_cleanable_overlays()
	for(var/cleanable_type in cleanables)
		var/obj/effect/decal/cleanable/C = cleanables[cleanable_type]
		if(C.overlayed_image)
			overlays += C.overlayed_image

/turf/proc/loc_to_string()
	var/text
	text = " ( [x], [y], [z])"// Desc is the <area name> (x, y)
	return text

/turf/process()
	return

// Handles whether an atom is able to enter the src turf
/turf/Enter(atom/movable/mover, atom/forget)
	if(!mover || !isturf(mover.loc))
		return FALSE

	var/override = SEND_SIGNAL(mover, COMSIG_MOVABLE_TURF_ENTER, src)
	override |= SEND_SIGNAL(src, COMSIG_TURF_ENTER, mover)
	if(override)
		return override & COMPONENT_TURF_ALLOW_MOVEMENT

	if(isobserver(mover) || istype(mover, /obj/item/projectile))
		return TRUE

	var/fdir = get_dir(mover, src)
	if(!fdir)
		return TRUE

	var/fd1 = fdir&(fdir-1) // X-component if fdir diagonal, 0 otherwise
	var/fd2 = fdir - fd1 // Y-component if fdir diagonal, fdir otherwise

	var/blocking_dir = 0 // The directions that the mover's path is being blocked by

	var/obstacle
	var/turf/T
	var/atom/A

	T = mover.loc
	blocking_dir |= T.BlockedExitDirs(mover, fdir)
	if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
		mover.Collide(T)
		return FALSE
	for(obstacle in T) //First, check objects to block exit
		if(mover == obstacle || forget == obstacle)
			continue
		A = obstacle
		if(!istype(A) || !A.can_block_movement)
			continue
		blocking_dir |= A.BlockedExitDirs(mover, fdir)
		if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
			mover.Collide(A)
			return FALSE

	for(var/atom/movable/thing as anything in contents)
		if(thing == mover || thing == mover.loc) // Multi tile objects and moving out of other objects
			continue
		thing.Cross(mover)

	// if we are thrown, moved, dragged, or in any other way abused by code - check our diagonals
	if(!mover.move_intentionally)
		// Check objects in adjacent turf EAST/WEST
		if(fd1 && fd1 != fdir)
			T = get_step(mover, fd1)
			if(T.BlockedExitDirs(mover, fd2) || T.BlockedPassDirs(mover, fd1))
				blocking_dir |= fd1
				if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
					mover.Collide(T)
					return FALSE
			for(obstacle in T)
				if(forget == obstacle)
					continue
				A = obstacle
				if(!istype(A) || !A.can_block_movement)
					continue
				if(A.BlockedExitDirs(mover, fd2) || A.BlockedPassDirs(mover, fd1))
					blocking_dir |= fd1
					if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
						mover.Collide(A)
						return FALSE

		// Check for borders in adjacent turf NORTH/SOUTH
		if(fd2 && fd2 != fdir)
			T = get_step(mover, fd2)
			if(T.BlockedExitDirs(mover, fd1) || T.BlockedPassDirs(mover, fd2))
				blocking_dir |= fd2
				if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
					mover.Collide(T)
					return FALSE
			for(obstacle in T)
				if(forget == obstacle)
					continue
				A = obstacle
				if(!istype(A) || !A.can_block_movement)
					continue
				if(A.BlockedExitDirs(mover, fd1) || A.BlockedPassDirs(mover, fd2))
					blocking_dir |= fd2
					if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
						mover.Collide(A)
						return FALSE
					break

	//Next, check the turf itself
	blocking_dir |= BlockedPassDirs(mover, fdir)
	if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
		mover.Collide(src)
		return FALSE
	for(obstacle in src) //Then, check atoms in the target turf
		if(forget == obstacle)
			continue
		A = obstacle
		if(!istype(A) || !A.can_block_movement)
			continue
		blocking_dir |= A.BlockedPassDirs(mover, fdir)
		if((!fd1 || blocking_dir & fd1) && (!fd2 || blocking_dir & fd2))
			if(!mover.Collide(A))
				return FALSE

	return TRUE //Nothing found to block so return success!

/turf/Entered(atom/movable/arrived, old_loc, list/old_locs)
	if(!istype(arrived))
		return

	SEND_SIGNAL(src, COMSIG_TURF_ENTERED, arrived)
	SEND_SIGNAL(arrived, COMSIG_MOVABLE_TURF_ENTERED, src)

	// Let explosions know that the atom entered
	for(var/datum/automata_cell/explosion/E in autocells)
		E.on_turf_entered(arrived)

/turf/Exited(atom/movable/gone, direction)
	if(!istype(gone))
		return


//zPassIn doesn't necessarily pass an atom!
//direction is direction of travel of air
/turf/proc/zPassIn(atom/movable/A, direction, turf/source)
	return FALSE

//direction is direction of travel of air
/turf/proc/zPassOut(atom/movable/A, direction, turf/destination, allow_anchored_movement)
	return FALSE

/// Precipitates a movable (plus whatever buckled to it) to lower z levels if possible and then calls zImpact()
/turf/proc/zFall(atom/movable/falling, levels = 1, force = FALSE, falling_from_move = FALSE)
	var/direction = DOWN
	var/turf/target = get_step_multiz(src, direction)
	if(!target)
		return FALSE
	var/isliving = isliving(falling)
	if(!isliving && !isobj(falling))
		return
	if(isliving)
		var/mob/living/falling_living = falling
		//relay this mess to whatever the mob is buckled to.
		if(falling_living.buckled)
			falling = falling_living.buckled
	if(!falling_from_move && falling.currently_z_moving)
		return
	if(!force && !falling.can_z_move(direction, src, target, ZMOVE_FALL_FLAGS))
		falling.set_currently_z_moving(FALSE, TRUE)
		return FALSE

	// So it doesn't trigger other zFall calls. Cleared on zMove.
	falling.set_currently_z_moving(CURRENTLY_Z_FALLING)

	if(istype(falling, /mob))
		var/mob/mob = falling
		mob.trainteleport(target)
	else
		falling.zMove(null, target, ZMOVE_CHECK_PULLEDBY)
	target.zImpact(falling, levels, src)

///Called each time the target falls down a z level possibly making their trajectory come to a halt. see __DEFINES/movement.dm.
/turf/proc/zImpact(atom/movable/falling, levels = 1, turf/prev_turf)
	var/flags = NONE
	var/list/falling_movables = falling.get_z_move_affected()
	var/list/falling_mov_names
	for(var/atom/movable/falling_mov as anything in falling_movables)
		falling_mov_names += falling_mov.name
	for(var/i in contents)
		var/atom/thing = i
		flags |= thing.intercept_zImpact(falling_movables, levels)
		if(flags & FALL_STOP_INTERCEPTING)
			break
	if(prev_turf && !(flags & FALL_NO_MESSAGE))
		for(var/mov_name in falling_mov_names)
			prev_turf.visible_message(SPAN_DANGER("[mov_name] falls through [prev_turf]!"))
	if(!(flags & FALL_INTERCEPTED) && zFall(falling, levels + 1))
		return FALSE
	for(var/atom/movable/falling_mov as anything in falling_movables)
		if(!(flags & FALL_RETAIN_PULL))
			falling_mov.stop_pulling()
		if(!(flags & FALL_INTERCEPTED))
			falling_mov.onZImpact(src, levels)
		if(falling_mov.pulledby && (falling_mov.z != falling_mov.pulledby.z || get_dist(falling_mov, falling_mov.pulledby) > 1))
			falling_mov.pulledby.stop_pulling()
	return TRUE

/turf/proc/is_plating()
	return 0
/turf/proc/is_asteroid_floor()
	return 0
/turf/proc/is_plasteel_floor()
	return 0
/turf/proc/is_light_floor()
	return 0
/turf/proc/is_grass_floor()
	return 0
/turf/proc/is_wood_floor()
	return 0
/turf/proc/is_carpet_floor()
	return 0
/turf/proc/return_siding_icon_state() //used for grass floors, which have siding.
	return 0

/turf/proc/inertial_drift(atom/movable/A as mob|obj)
	if(A.anchored)
		return
	if(!(A.last_move_dir)) return
	if((istype(A, /mob/) && src.x > 2 && src.x < (world.maxx - 1) && src.y > 2 && src.y < (world.maxy-1)))
		var/mob/M = A
		if(M.Process_Spacemove(1))
			M.inertia_dir  = 0
			return
		spawn(5)
			if((M && !(M.anchored) && !(M.pulledby) && (M.loc == src)))
				if(M.inertia_dir)
					step(M, M.inertia_dir)
					return
				M.inertia_dir = M.last_move_dir
				step(M, M.inertia_dir)
	return

/turf/proc/levelupdate()
	for(var/obj/O in src)
		if(O.level == 1)
			O.hide(intact_tile)

// A proc in case it needs to be recreated or badmins want to change the baseturfs
/turf/proc/assemble_baseturfs(turf/fake_baseturf_type)
	var/static/list/created_baseturf_lists = list()
	var/turf/current_target
	if(fake_baseturf_type)
		if(length(fake_baseturf_type)) // We were given a list, just apply it and move on
			baseturfs = fake_baseturf_type
			return
		current_target = fake_baseturf_type
	else
		if(length(baseturfs))
			return // No replacement baseturf has been given and the current baseturfs value is already a list/assembled
		if(!baseturfs)
			current_target = initial(baseturfs) || type // This should never happen but just in case...
			stack_trace("baseturfs var was null for [type]. Failsafe activated and it has been given a new baseturfs value of [current_target].")
		else
			current_target = baseturfs

	// If we've made the output before we don't need to regenerate it
	if(created_baseturf_lists[current_target])
		var/list/premade_baseturfs = created_baseturf_lists[current_target]
		if(length(premade_baseturfs))
			baseturfs = premade_baseturfs.Copy()
		else
			baseturfs = premade_baseturfs
		return baseturfs

	var/turf/next_target = initial(current_target.baseturfs)
	//Most things only have 1 baseturf so this loop won't run in most cases
	if(current_target == next_target)
		baseturfs = current_target
		created_baseturf_lists[current_target] = current_target
		return current_target
	var/list/new_baseturfs = list(current_target)
	for(var/i=0;current_target != next_target;i++)
		if(i > 100)
			// A baseturfs list over 100 members long is silly
			// Because of how this is all structured it will only runtime/message once per type
			stack_trace("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			message_admins("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			break
		new_baseturfs.Insert(1, next_target)
		current_target = next_target
		next_target = initial(current_target.baseturfs)

	baseturfs = new_baseturfs
	created_baseturf_lists[new_baseturfs[new_baseturfs.len]] = new_baseturfs.Copy()
	return new_baseturfs

// Creates a new turf
// new_baseturfs can be either a single type or list of types, formated the same as baseturfs. see turf.dm
/turf/proc/ChangeTurf(path, list/new_baseturfs, flags)
	switch(path)
		if(null)
			return
		if(/turf/baseturf_bottom)
			path = SSmapping.level_trait(z, ZTRAIT_BASETURF) || /turf/open/space
			if(!ispath(path))
				path = text2path(path)
				if(!ispath(path))
					warning("Z-level [z] has invalid baseturf '[SSmapping.level_trait(z, ZTRAIT_BASETURF)]'")
					path = /turf/open/space
		if(/turf/open/space/basic)
			// basic doesn't initialize and this will cause issues
			// no warning though because this can happen naturaly as a result of it being built on top of
			path = /turf/open/space

	//if(src.type == new_turf_path) // Put this back if shit starts breaking
	// return src

	var/sectors = linked_sectors
	var/pylons = linked_pylons
	var/old_snow = snow
	var/list/old_baseturfs = baseturfs
	var/old_pseudo_roof = pseudo_roof

	var/old_lighting_object = lighting_object
	var/old_outdoor_effect = outdoor_effect //MOJAVE MODULE OUTDOOR_EFFECTS
	var/old_lighting_corner_NE = lighting_corner_NE
	var/old_lighting_corner_SE = lighting_corner_SE
	var/old_lighting_corner_SW = lighting_corner_SW
	var/old_lighting_corner_NW = lighting_corner_NW
	var/old_directional_opacity = directional_opacity
	var/old_dynamic_lumcount = dynamic_lumcount

	changing_turf = TRUE
	qdel(src) //Just get the side effects and call Destroy
	var/turf/W = new path(src)
	for(var/i in W.contents)
		var/datum/A = i
		SEND_SIGNAL(A, COMSIG_ATOM_TURF_CHANGE, src)

	W.linked_sectors = sectors
	W.linked_pylons = pylons
	W.snow = old_snow
	if(new_baseturfs)
		W.baseturfs = new_baseturfs
	else
		W.baseturfs = old_baseturfs
	W.pseudo_roof = old_pseudo_roof

	lighting_corner_NE = old_lighting_corner_NE
	lighting_corner_SE = old_lighting_corner_SE
	lighting_corner_SW = old_lighting_corner_SW
	lighting_corner_NW = old_lighting_corner_NW

	dynamic_lumcount = old_dynamic_lumcount

	if(W.always_lit)
		W.add_overlay(GLOB.fullbright_overlay)
	else
		W.cut_overlay(GLOB.fullbright_overlay)

	if(SSlighting.initialized)
		W.lighting_object = old_lighting_object

		if(SSsunlighting.initialized)
			outdoor_effect = old_outdoor_effect

		directional_opacity = old_directional_opacity
		recalculate_directional_opacity()

		if(lighting_object && !lighting_object.needs_update)
			lighting_object.update()

	var/area/thisarea = get_area(W)
	if(thisarea.lighting_effect)
		W.add_overlay(thisarea.lighting_effect)

	W.levelupdate()
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_NEW, src, dir)
	return W

// Take off the top layer turf and replace it with the next baseturf down
/turf/proc/ScrapeAway(amount=1, flags)
	if(!amount)
		return
	if(length(baseturfs))
		var/list/new_baseturfs = baseturfs.Copy()
		var/turf_type = new_baseturfs[max(1, new_baseturfs.len - amount + 1)]
		while(ispath(turf_type, /turf/baseturf_skipover))
			amount++
			if(amount > new_baseturfs.len)
				CRASH("The bottomost baseturf of a turf is a skipover [src]([type])")
			turf_type = new_baseturfs[max(1, new_baseturfs.len - amount + 1)]
		new_baseturfs.len -= min(amount, new_baseturfs.len - 1) // No removing the very bottom
		if(new_baseturfs.len == 1)
			new_baseturfs = new_baseturfs[1]
		return ChangeTurf(turf_type, new_baseturfs, flags)

	if(baseturfs == type)
		return src

	return ChangeTurf(baseturfs, baseturfs, flags) // The bottom baseturf will never go away

/turf/proc/ReplaceWithLattice()
	src.ChangeTurf(/turf/open/space)
	new /obj/structure/lattice( locate(src.x, src.y, src.z) )

/turf/proc/AdjacentTurfs()
	var/L[] = new()
	for(var/turf/t in oview(src,1))
		if(!t.density)
			if(!LinkBlocked(src, t) && !TurfBlockedNonWindow(t))
				L.Add(t)
	return L

/turf/proc/AdjacentTurfsSpace()
	var/L[] = new()
	for(var/turf/t in oview(src,1))
		if(!t.density)
			if(!LinkBlocked(src, t) && !TurfBlockedNonWindow(t))
				L.Add(t)
	return L

/turf/proc/Distance(turf/t)
	if(get_dist(src,t) == 1)
		var/cost = (src.x - t.x) * (src.x - t.x) + (src.y - t.y) * (src.y - t.y)
		return cost
	else
		return get_dist(src,t)


//for xeno corrosive acid, 0 for unmeltable, 1 for regular, 2 for strong walls that require strong acid and more time.
/turf/proc/can_be_dissolved()
	return 0

/turf/proc/get_real_roof()
	var/turf/turf_above = SSmapping.get_turf_above(src)
	if(!turf_above)
		return src
	return turf_above.get_real_roof()

/turf/proc/can_air_strike(protection_penetration, turf/initial_turf)
	protection_penetration = protection_penetration - get_pylon_protection_level()
	var/turf/turf_above = SSmapping.get_turf_above(src)
	if(turf_above)
		if(istype(turf_above, /turf/closed/wall))
			var/turf/closed/wall/turf = turf_above
			if(turf && turf.hull)
				protection_penetration -= 19
			else
				protection_penetration -= turf_above.antipierce
		else
			protection_penetration -= turf_above.antipierce
	var/turf/turf_below = SSmapping.get_turf_below(src)
	if(get_sector_protection(src))
		if(turf_above)
			return turf_above
	else if(!turf_below)
		if(protection_penetration == 0)
			return src
		else
			if(turf_above)
				return turf_above
	else
		return turf_below.can_air_strike(protection_penetration, initial_turf)
	return FALSE

/turf/proc/air_hit(size = 1, turf/initial_turf)
	var/turf/turf_above = SSmapping.get_turf_above(src)
	var/turf/turf_below = SSmapping.get_turf_below(src)
	if(turf_above && !istype(turf_above, /turf/open/openspace))
		if(istype(turf_above, /turf/closed/wall))
			var/turf/closed/wall/turf = turf_above
			if(turf && !turf.hull)
				turf_above.ceiling_debris(size)
				turf_above.ChangeTurf(/turf/open/openspace)
		else
			turf_above.ceiling_debris(size)
			turf_above.ChangeTurf(/turf/open/openspace)
	else if(prob(10))
		return src
	if(!turf_below)
		return src
	return turf_below.air_hit(size, initial_turf)

/turf/proc/ceiling_debris_check(size = 1)
	return

/turf/proc/ceiling_debris(size = 1)
	var/turf/below_turf = SSmapping.get_turf_below(src)
	if(turf_flags & TURF_DEBRISED || !below_turf)
		return

	var/spread = round(sqrt(size)*1.5)
	var/list/turfs = list()
	for(var/turf/open/floor/F in range(below_turf, spread))
		turfs += F

	if(istype(src, /turf/open/floor/glass))
		playsound(below_turf, "sound/effects/Glassbr1.ogg", 60, 1)
		spawn(8)
			if(size > 1)
				below_turf.visible_message(SPAN_BOLDNOTICE("Shards of glass rain down from above!"))
			for(var/i = 1, i <= size, i++)
				new /obj/item/shard(pick(turfs))
				new /obj/item/shard(pick(turfs))
	else if(istype(src, /turf/open/floor/roof/metal) || istype(src, /turf/open/floor/roof/sheet) || istype(src, /turf/open/floor/roof/ship_hull))
		playsound(below_turf, "sound/effects/metal_crash.ogg", 60, 1)
		spawn(8)
			if(size > 1)
				below_turf.visible_message(SPAN_BOLDNOTICE("Pieces of metal crash down from above!"))
			for(var/i = 1, i <= size, i++)
				new /obj/item/stack/sheet/metal(pick(turfs))
	else if(istype(src, /turf/open/desert/rock) || istype(src, /turf/closed/wall/mineral))
		playsound(below_turf, "sound/effects/meteorimpact.ogg", 60, 1)
		spawn(8)
			if(size > 1)
				below_turf.visible_message(SPAN_BOLDNOTICE("Chunks of rock crash down from above!"))
			for(var/i = 1, i <= size, i++)
				new /obj/item/ore(pick(turfs))
				new /obj/item/ore(pick(turfs))
	else if(istype(src, /turf/open) || istype(src, /turf/closed))
		playsound(below_turf, "sound/effects/metal_crash.ogg", 60, 1)
		spawn(8)
			for(var/i =1 , i <= size, i++)
				new /obj/item/stack/sheet/metal(pick(turfs))
				new /obj/item/ore(pick(turfs))
	turf_flags |= TURF_DEBRISED

/turf/proc/ceiling_desc(mob/user)
	if(length(linked_pylons))
		var/protection_level = get_pylon_protection_level()
		if(protection_level < 10)
			return "The ceiling above is made of light resin. Doesn't look like it's going to stop much."
		if(protection_level < 20)
			return "The ceiling above is made of resin. Seems about as strong as a cavern roof."
		else
			return "The ceiling above is made of thick resin. Nothing is getting through that."

	var/area/A = get_area(src)
	switch(A.ceiling)
		if(CEILING_GLASS)
			return "The ceiling above is glass. That's not going stop anything."
		if(CEILING_METAL)
			return "The ceiling above is metal. You can't see through it with a camera from above, but that's not going to stop anything."
		if(CEILING_UNDERGROUND_ALLOW_CAS)
			return "It is underground. A thin cavern roof lies above. Doesn't look like it's going to stop much."
		if(CEILING_UNDERGROUND_BLOCK_CAS)
			return "It is underground. The cavern roof lies above. Can probably stop most ordnance."
		if(CEILING_UNDERGROUND_METAL_ALLOW_CAS)
			return "It is underground. The ceiling above is made of thin metal. Doesn't look like it's going to stop much."
		if(CEILING_UNDERGROUND_METAL_BLOCK_CAS)
			return "It is underground. The ceiling above is made of metal.  Can probably stop most ordnance."
		if(CEILING_DEEP_UNDERGROUND)
			return "It is deep underground. The cavern roof lies above. Nothing is getting through that."
		if(CEILING_DEEP_UNDERGROUND_METAL)
			return "It is deep underground. The ceiling above is made of thick metal. Nothing is getting through that."
		if(CEILING_REINFORCED_METAL)
			return "The ceiling above is heavy reinforced metal. Nothing is getting through that."
		else
			return "It is in the open."

/turf/proc/wet_floor()
	return

/turf/proc/get_cell(type)
	for(var/datum/automata_cell/C in autocells)
		if(istype(C, type))
			return C
	return null

/turf/handle_fall(mob/faller, forced)
	if(!forced)
		return
	playsound(src, get_sfx("bodyfall"), 50, 1)

//////////////////////////////////////////////////////////
/turf/proc/can_dig_xeno_tunnel()
	return FALSE

/turf/open/gm/can_dig_xeno_tunnel()
	return TRUE

/turf/open/gm/river/can_dig_xeno_tunnel()
	return FALSE

/turf/open/snow/can_dig_xeno_tunnel()
	return TRUE

/turf/open/mars/can_dig_xeno_tunnel()
	return TRUE

/turf/open/mars_cave/can_dig_xeno_tunnel()
	return TRUE

/turf/open/organic/can_dig_xeno_tunnel()
	return TRUE

/turf/open/floor/prison/can_dig_xeno_tunnel()
	return TRUE

/turf/open/desert/dirt/can_dig_xeno_tunnel()
	return TRUE

/turf/open/desert/rock/can_dig_xeno_tunnel()
	return TRUE

/turf/open/floor/ice/can_dig_xeno_tunnel()
	return TRUE

/turf/open/floor/wood/can_dig_xeno_tunnel()
	return TRUE

/turf/open/floor/corsat/can_dig_xeno_tunnel()
	return TRUE

/turf/closed/wall/almayer/research/containment/wall/divide/can_dig_xeno_tunnel()
	return FALSE

//what dirt type you can dig from this turf if any.
/turf/proc/get_dirt_type()
	return NO_DIRT

/turf/open/gm/get_dirt_type()
	return DIRT_TYPE_GROUND

/turf/open/organic/grass/get_dirt_type()
	return DIRT_TYPE_GROUND

/turf/open/gm/dirt/get_dirt_type()// looks like sand let it be sand
	return DIRT_TYPE_SAND

/turf/open/mars/get_dirt_type()
	return DIRT_TYPE_MARS

/turf/open/snow/get_dirt_type()
	if(bleed_layer)
		return DIRT_TYPE_SNOW
	else
		return DIRT_TYPE_GROUND

/turf/open/desert/dirt/get_dirt_type()
	return DIRT_TYPE_MARS

/turf/BlockedPassDirs(atom/movable/mover, target_dir)
	if(density)
		return BLOCKED_MOVEMENT
	return NO_BLOCKED_MOVEMENT

//whether the turf cancels a crusher charge
/turf/proc/stop_crusher_charge()
	return FALSE

/turf/proc/get_pylon_protection_level()
	var/protection_level = 0
	for(var/atom/pylon in linked_pylons)
		if(pylon.loc != null && istype(pylon, /obj/effect/alien/resin/special/pylon))
			var/obj/effect/alien/resin/special/pylon/P = pylon
			protection_level += P.protection_level
		else
			LAZYREMOVE(linked_pylons, pylon)

	return protection_level

/turf/proc/get_sector_protection()
	for(var/atom/sector in linked_sectors)
		if(sector.loc != null)
			if(istype(sector, /obj/structure/prop/sector_center))
				return TRUE
		else
			LAZYREMOVE(linked_sectors, sector)
	return FALSE

GLOBAL_LIST_INIT(blacklisted_automated_baseturfs, typecacheof(list(
	/turf/open/space,
	/turf/baseturf_bottom,
	)))

// Make a new turf and put it on top
// The args behave identical to PlaceOnBottom except they go on top
// Things placed on top of closed turfs will ignore the topmost closed turf
// Returns the new turf
/turf/proc/PlaceOnTop(list/new_baseturfs, turf/fake_turf_type, flags)
	var/area/turf_area = loc
	if(new_baseturfs && !length(new_baseturfs))
		new_baseturfs = list(new_baseturfs)
	flags = turf_area.PlaceOnTopReact(new_baseturfs, fake_turf_type, flags) // A hook so areas can modify the incoming args

	var/turf/newT
	if(flags & CHANGETURF_SKIP) // We haven't been initialized
		if(flags_atom & INITIALIZED)
			stack_trace("CHANGETURF_SKIP was used in a PlaceOnTop call for a turf that's initialized. This is a mistake. [src]([type])")
		assemble_baseturfs()
	if(fake_turf_type)
		if(!new_baseturfs) // If no baseturfs list then we want to create one from the turf type
			if(!length(baseturfs))
				baseturfs = list(baseturfs)
			var/list/old_baseturfs = baseturfs.Copy()
			if(!istype(src, /turf/closed))
				old_baseturfs += type
			newT = ChangeTurf(fake_turf_type, null, flags)
			newT.assemble_baseturfs(initial(fake_turf_type.baseturfs)) // The baseturfs list is created like roundstart
			if(!length(newT.baseturfs))
				newT.baseturfs = list(baseturfs)
			newT.baseturfs -= GLOB.blacklisted_automated_baseturfs
			newT.baseturfs.Insert(1, old_baseturfs) // The old baseturfs are put underneath
			return newT
		if(!length(baseturfs))
			baseturfs = list(baseturfs)
		insert_self_into_baseturfs()
		baseturfs += new_baseturfs
		return ChangeTurf(fake_turf_type, null, flags)
	if(!length(baseturfs))
		baseturfs = list(baseturfs)
	insert_self_into_baseturfs()
	var/turf/change_type
	if(length(new_baseturfs))
		change_type = new_baseturfs[new_baseturfs.len]
		new_baseturfs.len--
		if(new_baseturfs.len)
			baseturfs += new_baseturfs
	else
		change_type = new_baseturfs
	return ChangeTurf(change_type, null, flags)

/turf/proc/insert_self_into_baseturfs()
	baseturfs += type

/// Remove all atoms except observers, landmarks, docking ports - clearing up the turf contents
/turf/proc/empty(turf_type=/turf/open/space, baseturf_type, list/ignore_typecache, flags)
	var/static/list/ignored_atoms = typecacheof(list(/mob/dead, /obj/effect/landmark, /obj/docking_port))
	var/list/removable_contents = typecache_filter_list_reverse(GetAllContentsIgnoring(ignore_typecache), ignored_atoms)
	removable_contents -= src
	for(var/i in 1 to removable_contents.len)
		var/thing = removable_contents[i]
		qdel(thing, force = TRUE)

	if(turf_type)
		ChangeTurf(turf_type, baseturf_type, flags)

// Copy an existing turf and put it on top
// Returns the new turf
/turf/proc/CopyOnTop(turf/copytarget, ignore_bottom=1, depth=INFINITY, copy_air = FALSE)
	var/list/new_baseturfs = list()
	new_baseturfs += baseturfs
	new_baseturfs += type

	if(depth)
		var/list/target_baseturfs
		if(length(copytarget.baseturfs))
			// with default inputs this would be Copy(clamp(2, -INFINITY, baseturfs.len))
			// Don't forget a lower index is lower in the baseturfs stack, the bottom is baseturfs[1]
			target_baseturfs = copytarget.baseturfs.Copy(clamp(1 + ignore_bottom, 1 + copytarget.baseturfs.len - depth, copytarget.baseturfs.len))
		else if(!ignore_bottom)
			target_baseturfs = list(copytarget.baseturfs)
		if(target_baseturfs)
			target_baseturfs -= new_baseturfs & GLOB.blacklisted_automated_baseturfs
			new_baseturfs += target_baseturfs

	var/turf/newT = copytarget.copyTurf(src, copy_air)
	newT.baseturfs = new_baseturfs
	return newT

/turf/proc/copyTurf(turf/T)
	if(T.type != type)
		var/obj/O
		if(underlays.len) //we have underlays, which implies some sort of transparency, so we want to a snapshot of the previous turf as an underlay
			O = new()
			O.underlays.Add(T)
		T.ChangeTurf(type)
		if(underlays.len)
			T.underlays = O.underlays
	if(T.icon_state != icon_state)
		T.icon_state = icon_state
	if(T.icon != icon)
		T.icon = icon
	//if(color)
	// T.atom_colours = atom_colours.Copy()
	// T.update_atom_colour()
	if(T.dir != dir)
		T.setDir(dir)
	return T

/turf/proc/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = icon
	underlay_appearance.icon_state = icon_state
	underlay_appearance.dir = adjacency_dir
	return TRUE