/datum/action
	var/name = "Generic Action"
	var/icon_file = 'icons/mob/hud/actions.dmi'
	var/action_icon_state
	var/button_icon_state
	var/obj/target = null
	var/atom/movable/screen/action_button/button = null
	var/mob/owner
	var/cooldown = 0 // By default an action has no cooldown
	var/cost = 0 // By default an action has no cost -> will be utilized by skill actions/xeno actions
	var/action_flags = 0 // Check out __game.dm for flags
	/// Whether the action is hidden from its owner
	/// Useful for when you want to preserve action state while preventing
	/// a mob from using said action
	var/hidden = FALSE
	var/unique = TRUE
	/// A signal on the mob that will cause the action to activate
	var/listen_signal

/datum/action/New(Target, override_icon_state)
	target = Target
	button = new
	if(target && isatom(target))
		var/image/IMG = image(target.icon, button, target.icon_state)
		IMG.pixel_x = 0
		IMG.pixel_y = 0
		button.overlays += IMG
	button.source_action = src
	button.name = name
	if(button_icon_state)
		button.icon_state = button_icon_state
	button.overlays += image(icon_file, button, override_icon_state || action_icon_state)

/datum/action/Destroy()
	if(owner)
		remove_from(owner)
	QDEL_NULL(button)
	target = null
	return ..()

/datum/action/proc/update_button_icon()
	return

/datum/action/proc/action_activate()
	return

/// handler for when a keybind signal is received by the action, calls the action_activate proc asynchronous
/datum/action/proc/keybind_activation()
	SIGNAL_HANDLER
	if(can_use_action())
		INVOKE_ASYNC(src, PROC_REF(action_activate))

/datum/action/proc/can_use_action()
	if(hidden)
		return FALSE

	if(owner)
		return TRUE

/datum/action/proc/set_name(new_name)
	name = new_name
	button.name = new_name

/**
 * Gives an action to a mob and returns it
 *
 * If mob already has the action, unhide it if it's hidden
 *
 * Can pass additional initialization args
 */
/proc/give_action(mob/mob, action_path, ...)
	for(var/X in mob.actions)
		var/datum/action/action = X
		if(action.unique && action.type == action_path)
			if(action.hidden)
				action.hidden = FALSE
				mob.update_action_buttons()
			return action

	var/datum/action/action
	/// Cannot use arglist for both cases because of
	/// unique BYOND handling of args in New
	if(length(args) > 2)
		action = new action_path(arglist(args.Copy(3)))
	else
		action = new action_path()
	action.give_to(mob)
	return action

/datum/action/proc/give_to(mob/target_mob)
	SHOULD_CALL_PARENT(TRUE)
	if(owner)
		if(owner == target_mob)
			return
		remove_from(owner)
	SEND_SIGNAL(src, COMSIG_ACTION_GIVEN, target_mob)
	target_mob.handle_add_action(src)
	if(listen_signal)
		RegisterSignal(target_mob, listen_signal, PROC_REF(keybind_activation))
	owner = target_mob

/mob/proc/handle_add_action(datum/action/action)
	LAZYADD(actions, action)
	if(client)
		client.screen += action.button
	update_action_buttons()

/proc/remove_action(mob/mob, action_path)
	for(var/X in mob.actions)
		var/datum/action/action = X
		if(action.type == action_path)
			action.remove_from(mob)
			return action

/datum/action/proc/remove_from(mob/mob)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTION_REMOVED, mob)
	mob.handle_remove_action(src)
	owner = null

/mob/proc/handle_remove_action(datum/action/action)
	actions?.Remove(action)
	if(client)
		client.screen -= action.button
	update_action_buttons()

/mob/living/carbon/human/handle_remove_action(datum/action/action)
	if(selected_ability == action)
		action.action_activate()
	return ..()

/proc/hide_action(mob/mob, action_path)
	for(var/X in mob.actions)
		var/datum/action/action = X
		if(action.type == action_path)
			action.hidden = TRUE
			mob.update_action_buttons()
			return action

/datum/action/proc/hide_from(mob/mob)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTION_HIDDEN, mob)
	hidden = TRUE
	mob.update_action_buttons()

/proc/unhide_action(mob/mob, action_path)
	for(var/X in mob.actions)
		var/datum/action/action = X
		if(action.type == action_path)
			action.hidden = FALSE
			mob.update_action_buttons()
			return action

/datum/action/proc/unhide_from(mob/mob)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTION_UNHIDDEN, mob)
	hidden = FALSE
	mob.update_action_buttons()


/datum/action/item_action
	name = "Use item"
	var/obj/item/holder_item //the item that has this action in its list of actions. Is not necessarily the target
								//e.g. gun attachment action: target = attachment, holder = gun.
	unique = FALSE

/datum/action/item_action/New(Target, obj/item/holder)
	..()
	if(!holder)
		holder = target
	holder_item = holder
	LAZYADD(holder_item.actions, src)
	name = "Use [target]"
	button.name = name

	update_button_icon()

/datum/action/item_action/Destroy()
	LAZYREMOVE(holder_item.actions, src)
	holder_item = null
	return ..()

/datum/action/item_action/action_activate()
	if(target)
		var/obj/item/I = target
		I.ui_action_click(owner, holder_item)

/datum/action/item_action/can_use_action()
	if(ishuman(owner) && !owner.is_mob_incapacitated() && owner.can_action)
		return TRUE

/datum/action/item_action/update_button_icon()
	button.overlays.Cut()
	var/mutable_appearance/item_appearance = mutable_appearance(target.icon, target.icon_state, plane = ABOVE_HUD_PLANE)
	for(var/overlay in target.overlays)
		item_appearance.overlays += overlay
	button.overlays += item_appearance

/datum/action/item_action/toggle/New(Target)
	..()
	name = "Toggle [target]"
	button.name = name

//This is the proc used to update all the action buttons.
/mob/proc/update_action_buttons(reload_screen)
	if(!client)
		return

	if(!hud_used)
		create_hud()

	if(hud_used.hud_version == HUD_STYLE_NOHUD)
		return

	var/button_number = 0

	if(hud_used.action_buttons_hidden)
		for(var/datum/action/action in actions)
			action.button.screen_loc = null
			if(reload_screen)
				client.screen += action.button
	else
		for(var/datum/action/action in actions)
			var/atom/movable/screen/action_button/button = action.button
			if(reload_screen)
				client.screen += button
			if(action.hidden)
				button.screen_loc = null
				continue
			button_number++
			button.screen_loc = button.get_button_screen_loc(button_number)

		if(!button_number)
			hud_used.hide_actions_toggle.screen_loc = null
			if(reload_screen)
				client.screen += hud_used.hide_actions_toggle
			return

	hud_used.hide_actions_toggle.screen_loc = hud_used.hide_actions_toggle.get_button_screen_loc(button_number+1)

	if(reload_screen)
		client.screen += hud_used.hide_actions_toggle