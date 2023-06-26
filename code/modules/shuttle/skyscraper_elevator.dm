// -- Docks
/obj/docking_port/stationary/sselevator
	name = "Sky Scraper Elevator Floor"
	id = MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR
	width = 7
	height = 7

/obj/docking_port/stationary/sselevator/register()
	id = "[MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR]_[src.z]"
	. = ..()
	GLOB.ss_elevator_floors["[id]"] = src

// -- Shuttles

/obj/docking_port/mobile/sselevator
	name = "sky scraper elevator"
	id = MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR
	width = 7
	height = 7

	landing_sound = null
	ignition_sound = 'sound/machines/asrs_raising.ogg'
	ambience_flight = null
	ambience_idle = null
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)

	custom_ceiling = /turf/open/floor/roof/ship_hull/lab

	var/target_floor = 102
	var/floor_offset = 0
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/door
	var/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button
	var/list/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/doors = list()
	var/list/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button/buttons = list()
	var/list/turf/closed/shuttle/elevator/gears/sci/gears = list()
	var/list/disabled_floors = list()
	var/list/called_floors = list()
	var/called = 1
	var/next_moving = 0
	var/moving = FALSE
	var/cooldown = FALSE
	var/move_delay = 3 SECONDS

/obj/docking_port/mobile/sselevator/register()
	. = ..()
	SSshuttle.sky_scraper_elevator = src
	for(var/i=1;i<101;i++)
		disabled_floors["[i]"] = TRUE
	disabled_floors["100"] = FALSE
	for(var/i=1;i<101;i++)
		called_floors["[i]"] = FALSE

/obj/docking_port/mobile/sselevator/request(obj/docking_port/stationary/S) //No transit, no ignition, just a simple up/down platform
	initiate_docking(S, force = TRUE)

/obj/docking_port/mobile/sselevator/afterShuttleMove()
	if(!floor_offset)
		return
	if(z == target_floor)
		on_stop_actions()
		cooldown = TRUE
		moving = FALSE
		target_floor = 0
		spawn(15 SECONDS)
			cooldown = FALSE
			if(next_moving)
				calc_elevator_order(next_moving)
				next_moving = 0

	else if(called_floors["[z - floor_offset]"] == TRUE)
		sleep(2 SECONDS)
		on_stop_actions()
		sleep(13 SECONDS)
		on_move_actions()
		move_elevator()
	else
		move_elevator()

/obj/docking_port/mobile/sselevator/proc/on_move_actions()
	button.update_icon("_animated")
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/B = doors["[z]"]
	INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, close_and_lock))
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, close_and_lock))
	for(var/turf/closed/shuttle/elevator/gears/sci/G in gears)
		G.start()

/obj/docking_port/mobile/sselevator/proc/on_stop_actions()
	buttons["[z]"]?.update_icon()
	button.update_icon()
	called_floors["[z - floor_offset]"] = FALSE
	called--
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/B = doors["[z]"]
	INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))
	for(var/turf/closed/shuttle/elevator/gears/sci/G in gears)
		G.stop()

/obj/docking_port/mobile/sselevator/proc/move_elevator()
	var/floor_to_move = z > target_floor ? z-1 : z+1
	button.visible_message(SPAN_NOTICE("Лифт отправляется и прибудет на этаж [floor_to_move - floor_offset]. Пожалуйста стойте в стороне от дверей."))
	playsound(return_center_turf(), ignition_sound, 60, 0, falloff = 4)
	sleep(4 SECONDS)
	calculate_move_delay(floor_to_move)
	SSshuttle.moveShuttleToDock(id, GLOB.ss_elevator_floors["[MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR]_[floor_to_move]"], move_delay, FALSE)

/obj/docking_port/mobile/sselevator/proc/calculate_move_delay(floor_calc)
	if(z > target_floor ? z - floor_calc > 4 : floor_calc - z > 4)
		move_delay--
	else
		move_delay += 0.2 SECONDS
	move_delay = Clamp(move_delay, 3 SECONDS, 1 SECONDS)

/obj/docking_port/mobile/sselevator/proc/calc_elevator_order(floor_calc)
	if(floor_calc)
		called++
		buttons["[floor_calc]"].update_icon("_animated")
		called_floors["[floor_calc - floor_offset]"] = TRUE
		switch(moving)
			if("DOWN")
				if(floor_calc > next_moving)
					next_moving = floor_calc
				else if(floor_calc < target_floor)
					target_floor = floor_calc
			if("UP")
				if(floor_calc > target_floor)
					target_floor = floor_calc
				else if(floor_calc < next_moving)
					next_moving = floor_calc
			else
				if((floor_calc > next_moving > z) || (floor_calc < next_moving < z))
					next_moving = floor_calc
				if((floor_calc > target_floor > z) || (floor_calc < target_floor < z))
					target_floor = floor_calc
	if(!moving && !cooldown)
		target_floor = floor_calc
		moving = z > target_floor ? "DOWN" : "UP"
		on_move_actions()
		move_elevator()

/obj/docking_port/stationary/sselevator/floor_roof
	roundstart_template = /datum/map_template/shuttle/sky_scraper_elevator

/obj/docking_port/stationary/sselevator/floor_roof/load_roundstart()
	. = ..()
	SSshuttle.sky_scraper_elevator.target_floor = z
	SSshuttle.sky_scraper_elevator.floor_offset = z - 100
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/B = SSshuttle.sky_scraper_elevator.doors["[z]"]
	INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))
	SSshuttle.sky_scraper_elevator.on_stop_actions()

//Console

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator
	name = "'S95 v2' elevator console"
	desc = "Controls for the 'S95 v2' elevator."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "elevator_screen"
	var/floor
	var/obj/docking_port/mobile/sselevator/elevator

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/Initialize(mapload, ...)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/LateInitialize()
	. = ..()
	spawn()
		UNTIL(SSshuttle.sky_scraper_elevator)
		elevator = SSshuttle.sky_scraper_elevator
		if(floor != "control")
			floor = z
			elevator.buttons["[floor]"] = src

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/Destroy()
	if(floor != "control")
		elevator.buttons["[floor]"] -= src
	. = ..()

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/update_icon(icon_update = "")
	icon_state = initial(icon_state) + icon_update

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Доступ Запрещен!"))
		return
	if(inoperable())
		return
	if(!isRemoteControlling(user))
		user.set_interaction(src)
	tgui_interact(user)

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/tgui_interact(mob/user, datum/tgui/ui)
	// Update UI
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		// Open UI
		ui = new(user, src, "Elevator", name, 600, 600)
		ui.open()

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/ui_data()
	var/list/data = list()
	data["buttons"] = list()
	for(var/i=1;i<101;i++)
		data["buttons"] += list(list(
			id = i, title = "Floor [i]", disabled = elevator.disabled_floors["[i]"], called = elevator.called_floors["[i]"],
		))
	return data

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	if(action == "click")
		var/target_floor = params["id"] + elevator.floor_offset
		if(elevator.z == target_floor || elevator.called_floors["[target_floor - elevator.floor_offset]"])
			return
		playsound(src, 'sound/machines/click.ogg', 15, 1)
		elevator.calc_elevator_order(target_floor)
		return
	return

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock, idnum, override)
	. = ..()
	if(istype(port, /obj/docking_port/mobile/sselevator))
		var/obj/docking_port/mobile/sselevator/L = port
		L.button = src

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button
	desc = "The remote controls for the 'S95 v2' elevator."

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Доступ Запрещен!"))
		return
	if(inoperable() || elevator.z == floor)
		return
	if(elevator.disabled_floors["[floor - elevator.floor_offset]"])
		visible_message(SPAN_WARNING("Лифт не может отправится на этот этаж, обратитесь на ближайший пост службы безопасности!"))
		return
	if(elevator.called_floors["[floor - elevator.floor_offset]"])
		visible_message(SPAN_NOTICE("Лифт уже едет на этот этаж, ожидайте."))
		return
	call_elevator(user)

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button/proc/call_elevator()
	playsound(src, 'sound/machines/click.ogg', 15, 1)
	visible_message(SPAN_NOTICE("Лифт вызван, ожидайте."))
	elevator.calc_elevator_order(floor)


/obj/structure/machinery/computer/security_blocker
	name = "Security Controller"
	desc = "Used to control floors of sky scraper."
	icon_state = "terminal1"

	density = 1
	unacidable = 1
	anchored = 1
	indestructible = TRUE

	var/generate_time = 1 MINUTES
	var/segment_time = 10 SECONDS

	var/total_segments = 5 // total number of times the hack is required
	var/completed_segments = 0 // what segment we are on, (once this hits total)
	var/current_timer

	var/working = FALSE
	var/printed = FALSE

	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/stairs_doors = list()
	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/elevator_doors = list()
	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/move_lock_doors = list()
	var/list/obj/structure/machinery/siren/sirens = list()
	var/obj/docking_port/mobile/sselevator/elevator
	var/list/locked = list("stairs" = FALSE, "elevator" = FALSE)

	var/list/technobabble = list(
		"Запускаем терминал",
		"Критическая ошибка, поиск причины",
		"ОШИБКА, недостаточный доступ для проведения операции",
		"Подключаемся к главному серверу W-Y, скачиваем протоколы обхода защиты",
		"Протоколы скачаны, запустите их для снятия блокировки, хорошего дня (C) W-Y General Security Systems"
	)

/obj/structure/machinery/computer/security_blocker/Initialize()
	. = ..()
	GLOB.skyscrapers_sec_comps["[z]"] += src
	segment_time = round(segment_time/(max(length(GLOB.skyscrapers_sec_comps),1)*0.01))
	return INITIALIZE_HINT_LATELOAD

/obj/structure/machinery/computer/security_blocker/LateInitialize()
	. = ..()
	spawn()
		UNTIL(SSshuttle.sky_scraper_elevator)
		elevator = SSshuttle.sky_scraper_elevator
		for(var/obj/structure/machinery/siren/S in sirens)
			S.siren_warning_start("ТРЕВОГА, КРИТИЧЕСКАЯ СИТУАЦИЯ, ЗАПУЩЕН ПРОТОКОЛ МАКСИМАЛЬНОЙ БЕЗОПАСНОСТИ, ЭТАЖ [z-elevator.floor_offset]")

/obj/structure/machinery/computer/security_blocker/ex_act(severity)
	return

/obj/structure/machinery/computer/security_blocker/process()
	. = ..()
	if((. && current_timer > 0) || current_timer == 0)
		updateUsrDialog()
		return

	deltimer(current_timer)
	current_timer = null
	working = FALSE
	visible_message("<b>[src]</b> выключается из-за отсутствия питания.")
	updateUsrDialog()
	return PROCESS_KILL

/obj/structure/machinery/computer/security_blocker/attackby(mob/user as mob)
	interact(user)

/obj/structure/machinery/computer/security_blocker/attack_hand(mob/user as mob)
	. = ..()
	interact(user)

/obj/structure/machinery/computer/security_blocker/attack_remote(mob/user as mob)
	interact(user)

/obj/structure/machinery/computer/security_blocker/interact(mob/user)
	. = ..()
	user.set_interaction(src)
	var/dat = ""
	dat += "<div align='center'>Терминал безопасности [z-elevator.floor_offset] этажа</a></div>"
	dat += "<br/><span><b>Протокол безопасности</b>: [printed ? "отключен" : "включен"]</span>"
	if(printed)
		if(istype(user,/mob/living/carbon/xenomorph/queen))
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=unlock'>Разблокировать [z-elevator.floor_offset] этаж</a></div>"
		else if(current_timer)
			dat += "<br/><span><b>Терминал заблокирован</b></span>"
			dat += "<br/><span><b>Оставшееся время</b>: [current_timer ? round(timeleft(current_timer) * 0.1, 2) : 0.0]</span>"
		else
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=stairs'>Разблокировать/Заблокировать лестницу</a></div>"
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=elevator'>Разблокировать/Заблокировать лифт</a></div>"

	else
		dat += "<div align='center'><a href='?src=[REF(src)];generate=1'>Запустить программу</a></div>"
		dat += "<br/>"
		dat += "<hr/>"
		dat += "<div align='center'><h2>Статус</h2></div>"

		var/message = "Ошибка"
		if(completed_segments >= total_segments)
			message = "Коды сгенерированны. Запустите программу для разблокировки."
		else if(current_timer || working)
			message = "Программа запущена"
		else if(completed_segments == 0)
			message = "Ожидание"
		else if(completed_segments < total_segments)
			message = "Требуется перезапуск. Пожалуйста перезапустите программу"
		else
			message = "Неизвестно"

		var/progress = round((completed_segments / total_segments) * 100)

		dat += "<br/><span><b>Прогресс</b>: [progress]%</span>"
		dat += "<br/><span><b>Оставшееся время</b>: [current_timer ? round(timeleft(current_timer) * 0.1, 2) : 0.0]</span>"
		dat += "<br/><span><b>Сообщение</b>: [message]</span>"

		var/flair = ""
		for(var/i in 1 to completed_segments)
			flair += "[technobabble[i]]<br/>"

		dat += "<br/><br/><span style='font-family: monospace, monospace;'>[flair]</span>"

	dat += "<div align='center'><h1>(C) W-Y General Security Systems</h1></div>"

	show_browser(user, dat, "Security Floor Controller", "security_blocker", "size=600x700")
	onclose(user, "security_blocker")

/obj/structure/machinery/computer/security_blocker/Topic(href, href_list)
	if(..())
		return

	add_fingerprint(usr)

	if(href_list["blastdoors"])
		var/stairs = locked["stairs"]
		var/elevator = locked["elevator"]
		switch(href_list["blastdoors"])
			if("stairs")
				if(!elevator)
					for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B in stairs_doors)
						if(stairs)
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
						else
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, close))

					locked["stairs"] = !locked["stairs"]
					to_chat(usr, SPAN_WARNING("Лестница [locked["elevator"] ? "раз" : "за"]блокирована."))
				else
					to_chat(usr, SPAN_WARNING("Блокировка лифта не допускает блокировку лестницы!"))
					return
			if("elevator")
				if(!stairs)
					for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B in elevator_doors)
						if(elevator)
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
						else
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, close))

					locked["elevator"] = !locked["elevator"]
					to_chat(usr, SPAN_WARNING("Лифт [locked["elevator"] ? "раз" : "за"]блокирован."))
				else
					to_chat(usr, SPAN_WARNING("Блокировка лестницы не допускает блокировку лифта!"))
					return
			if("unlock")
				for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B in stairs_doors + elevator_doors + move_lock_doors)
					INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
		current_timer = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, process)), segment_time)

	else if(href_list["generate"])
		if(working || current_timer)
			to_chat(usr, SPAN_WARNING("Программа восстановления уже запущена."))
			return

		if(!printed && completed_segments == total_segments)
			printed = TRUE
			usr.visible_message("[usr] запустил программу для разблокировки консоли.", "Вы запустили программу для разблокировки консоли.")
			if(!do_after(usr, round(generate_time/5), INTERRUPT_ALL, BUSY_ICON_HOSTILE))
				printed = FALSE
				return

			unlock_floor()
			return

		working = TRUE
		addtimer(VARSET_CALLBACK(src, working, FALSE), segment_time)

		usr.visible_message("[usr] запустил программу для восстановления консоли.", "Вы запустили программу для восстановления консоли.")
		if(!do_after(usr, segment_time, INTERRUPT_ALL, BUSY_ICON_HOSTILE, CALLBACK(src, TYPE_PROC_REF(/datum, process))))
			working = FALSE
			return

		current_timer = addtimer(CALLBACK(src, PROC_REF(complete_segment)), generate_time, TIMER_STOPPABLE)

	updateUsrDialog()

/obj/structure/machinery/computer/security_blocker/proc/complete_segment()
	playsound(src, 'sound/machines/ping.ogg', 25, 1)
	deltimer(current_timer)
	current_timer = null
	completed_segments = min(completed_segments + 1, total_segments)

	if(completed_segments == total_segments)
		visible_message(SPAN_NOTICE("[src] beeps as it ready to generate code."))
		return
	visible_message(SPAN_NOTICE("[src] beeps as it program requires attention."))

/obj/structure/machinery/computer/security_blocker/proc/unlock_floor()
	elevator.disabled_floors["[z-elevator.floor_offset]"] = FALSE
	for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B in move_lock_doors)
		INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
	visible_message(SPAN_NOTICE("[src] beeps as it finishes generating code."))