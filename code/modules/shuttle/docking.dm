/// This is the main proc. It instantly moves our mobile port to stationary port `new_dock`.
/obj/docking_port/mobile/proc/initiate_docking(obj/docking_port/stationary/new_dock, movement_direction, force=FALSE)
	// Crashing this ship with NO SURVIVORS

	if(!new_dock)
		return DOCKING_NULL_DESTINATION

	if(new_dock.get_docked() == src)
		remove_ripples()
		return DOCKING_SUCCESS

	if(!force)
		if(!check_dock(new_dock))
			remove_ripples()
			return DOCKING_BLOCKED
		if(!canMove())
			remove_ripples()
			return DOCKING_IMMOBILIZED

	var/obj/docking_port/stationary/old_dock = get_docked()

	// The area that gets placed under where the shuttle moved from
	var/underlying_area_type = SHUTTLE_DEFAULT_UNDERLYING_AREA

	if(old_dock) //Dock overwrites
		underlying_area_type = old_dock.area_type

	/**************************************************************************************************************
		Both lists are associative with a turf:bitflag structure. (new_turfs bitflag space unused currently)
		The bitflag contains the data for what inhabitants of that coordinate should be moved to the new location
		The bitflags can be found in __DEFINES/shuttles.dm
	*/
	var/list/old_turfs = return_ordered_turfs(x, y, z, dir)
	var/list/new_turfs = return_ordered_turfs(new_dock.x, new_dock.y, new_dock.z, new_dock.dir)
	CHECK_TICK
	/**************************************************************************************************************/

	// The underlying old area is the area assumed to be under the shuttle's starting location
	// If it no longer/has never existed it will be created
	var/area/underlying_old_area = GLOB.areas_by_type[underlying_area_type]
	if(!underlying_old_area)
		underlying_old_area = new underlying_area_type(null)

	var/rotation = 0
	if(new_dock.dir != dir) //Even when the dirs are the same rotation is coming out as not 0 for some reason
		rotation = dir2angle(new_dock.dir)-dir2angle(dir)
		if((rotation % 90) != 0)
			rotation += (rotation % 90) //diagonal rotations not allowed, round up
		rotation = SIMPLIFY_DEGREES(rotation)

	if(!movement_direction)
		movement_direction = turn(preferred_direction, 180)

	var/list/moved_atoms = list() //Everything not a turf that gets moved in the shuttle
	var/list/areas_to_move = list() //unique assoc list of areas on turfs being moved

	if(!istype(new_dock, /obj/docking_port/stationary/transit) && crashing)
		new_dock.on_crash()
		on_crash()
		crashing = FALSE

	. = preflight_check(old_turfs, new_turfs, areas_to_move, rotation)
	if(.)
		remove_ripples()
		return

	/*******************************************Hiding turfs if necessary*******************************************/
	// TODO: Move this somewhere sane
	var/list/new_hidden_turfs
	if(hidden)
		new_hidden_turfs = list()
		for(var/i in 1 to old_turfs.len)
			CHECK_TICK
			var/turf/old_turf = old_turfs[i]
			if(old_turfs[old_turf] & MOVE_TURF)
				new_hidden_turfs += new_turfs[i]
		SSshuttle.update_hidden_docking_ports(null, new_hidden_turfs)
	/***************************************************************************************************************/

	if(!force)
		if(!check_dock(new_dock))
			remove_ripples()
			return DOCKING_BLOCKED
		if(!canMove())
			remove_ripples()
			return DOCKING_IMMOBILIZED

	// Moving to the new location will trample the ripples there at the exact
	// same time any mobs there are trampled, to avoid any discrepancy where
	// the ripples go away before it is safe.
	takeoff(old_turfs, new_turfs, moved_atoms, rotation, movement_direction, old_dock, underlying_old_area)

	CHECK_TICK

	cleanup_runway(new_dock, old_turfs, new_turfs, areas_to_move, moved_atoms, rotation, movement_direction, underlying_old_area)

	CHECK_TICK

	/*******************************************Unhiding turfs if necessary******************************************/
	if(new_hidden_turfs)
		SSshuttle.update_hidden_docking_ports(hidden_turfs, null)
		hidden_turfs = new_hidden_turfs
	/****************************************************************************************************************/

// check_poddoors()
	old_dock?.on_departure(src)
	new_dock.last_dock_time = world.time
	new_dock.on_arrival(src)
	setDir(new_dock.dir)

	// remove any stragglers just in case, and clear the list
	remove_ripples()
	return DOCKING_SUCCESS

/obj/docking_port/mobile/proc/preflight_check(list/old_turfs, list/new_turfs, list/areas_to_move, rotation)
	for(var/i in 1 to length(old_turfs))
		CHECK_TICK
		var/turf/old_turf = old_turfs[i]
		var/turf/new_turf = new_turfs[i]
		if(!new_turf)
			return DOCKING_NULL_DESTINATION
		if(!old_turf)
			return DOCKING_NULL_SOURCE

		var/area/old_area = old_turf.loc
		var/move_mode = old_area.beforeShuttleMove(shuttle_areas) //areas

		for(var/atom/movable/moving_atom as anything in old_turf.contents)
			CHECK_TICK
			if(moving_atom.loc != old_turf) //fix for multi-tile objects
				continue
			move_mode = moving_atom.beforeShuttleMove(new_turf, rotation, move_mode, src) //atoms

		move_mode = old_turf.fromShuttleMove(new_turf, move_mode) //turfs
		move_mode = new_turf.toShuttleMove(old_turf, move_mode, src) //turfs

		if(move_mode & MOVE_AREA)
			areas_to_move[old_area] = TRUE

		old_turfs[old_turf] = move_mode

/obj/docking_port/mobile/proc/takeoff(list/old_turfs, list/new_turfs, list/moved_atoms, rotation, movement_direction, old_dock, area/underlying_old_area)
	for(var/i in 1 to old_turfs.len)
		var/turf/old_turf = old_turfs[i]
		var/turf/new_turf = new_turfs[i]
		var/move_mode = old_turfs[old_turf]
		if(move_mode & MOVE_CONTENTS)
			for(var/k in old_turf)
				var/atom/movable/moving_atom = k
				if(moving_atom.loc != old_turf) //fix for multi-tile objects
					continue
				moving_atom.onShuttleMove(new_turf, old_turf, movement_force, movement_direction, old_dock, src) //atoms
				moved_atoms[moving_atom] = old_turf

		if(move_mode & MOVE_TURF)
			old_turf.onShuttleMove(new_turf, movement_force, movement_direction, src) //turfs

		if(move_mode & MOVE_AREA)
			var/area/shuttle_area = old_turf.loc
			shuttle_area.onShuttleMove(old_turf, new_turf, underlying_old_area) //areas

/obj/docking_port/mobile/proc/cleanup_runway(obj/docking_port/stationary/new_dock, list/old_turfs, list/new_turfs, list/areas_to_move, list/moved_atoms, rotation, movement_direction, area/underlying_old_area)
	underlying_old_area.afterShuttleMove()

	// Parallax handling
	// This needs to be done before the atom after move
	var/new_parallax_dir = FALSE
	if(istype(new_dock, /obj/docking_port/stationary/transit))
		new_parallax_dir = preferred_direction
	for(var/i in 1 to areas_to_move.len)
		CHECK_TICK
		var/area/internal_area = areas_to_move[i]
		internal_area.afterShuttleMove(new_parallax_dir) //areas

	for(var/i in 1 to old_turfs.len)
		CHECK_TICK
		if(!(old_turfs[old_turfs[i]] & MOVE_TURF))
			continue

		var/turf/old_turf = old_turfs[i]
		var/turf/new_turf = new_turfs[i]
		var/turf/new_ceiling = get_step_multiz(new_turf, UP)
		if(new_turf.outdoor_effect)
			qdel(new_turf.outdoor_effect, TRUE)
		if(old_turf.outdoor_effect)
			qdel(old_turf.outdoor_effect, TRUE)

		if(new_ceiling)
			if(!new_ceiling.baseturfs || istype(/turf/open/openspace, pick(new_ceiling.baseturfs)))
				new_ceiling.ChangeTurf(custom_ceiling)
			else
				if(length(new_ceiling.baseturfs) > 1)
					new_ceiling.baseturfs = list(new_ceiling.baseturfs[1], custom_ceiling) + new_ceiling.baseturfs.Copy(2, length(new_ceiling.baseturfs))
				else
					new_ceiling.baseturfs = list(custom_ceiling) + new_ceiling.baseturfs
		else
			new_turf.pseudo_roof = custom_ceiling

		new_turf.afterShuttleMove(old_turf, rotation)
		GLOB.SUNLIGHT_QUEUE_WORK += new_turf

		var/turf/old_ceiling = get_step_multiz(old_turf, UP)
		if(!old_ceiling)
			var/obj/effect/mapping_helpers/sunlight/pseudo_roof_setter/presetted_pseudo = locate(/obj/effect/mapping_helpers/sunlight/pseudo_roof_setter) in old_turf
			old_turf.pseudo_roof = presetted_pseudo ? presetted_pseudo.pseudo_roof : initial(old_turf.pseudo_roof)
		else if(istype(old_ceiling, custom_ceiling))
			var/turf/open/floor/roof/old_shuttle_ceiling = old_ceiling
			old_shuttle_ceiling.ScrapeAway()
		else
			old_ceiling.baseturfs -= custom_ceiling
		GLOB.SUNLIGHT_QUEUE_WORK += old_turf

	for(var/i in 1 to moved_atoms.len)
		CHECK_TICK
		var/atom/movable/moved_object = moved_atoms[i]
		if(QDELETED(moved_object))
			continue
		var/turf/old_turf = moved_atoms[moved_object]
		moved_object.afterShuttleMove(old_turf, movement_force, dir, preferred_direction, movement_direction, rotation)//atoms

	// lateShuttleMove (There had better be a really good reason for additional stages beyond this)

	underlying_old_area.lateShuttleMove()

	for(var/i in 1 to areas_to_move.len)
		CHECK_TICK
		var/area/internal_area = areas_to_move[i]
		internal_area.lateShuttleMove()

	for(var/i in 1 to old_turfs.len)
		CHECK_TICK
		if(!(old_turfs[old_turfs[i]] & MOVE_CONTENTS | MOVE_TURF))
			continue
		var/turf/old_turf = old_turfs[i]
		var/turf/new_turf = new_turfs[i]
		new_turf.lateShuttleMove(old_turf)
		old_turf.get_sky_and_weather_states()

	for(var/i in 1 to moved_atoms.len)
		CHECK_TICK
		var/atom/movable/moved_object = moved_atoms[i]
		if(QDELETED(moved_object))
			continue
		var/turf/old_turf = moved_atoms[moved_object]
		moved_object.lateShuttleMove(old_turf, movement_force, movement_direction)
