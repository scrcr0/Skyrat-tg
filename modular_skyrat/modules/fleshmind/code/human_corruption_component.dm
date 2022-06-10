/datum/component/human_corruption
	/// A hard ref to our controller.
	var/datum/fleshmind_controller/our_controller
	var/static/list/actions_to_give = list(
		/datum/action/cooldown/fleshmind_create_structure,
		/datum/action/cooldown/fleshmind_flesh_call,
		/datum/action/innate/fleshmind_flesh_chat,
	)
	var/list/granted_actions = list()
	/// A list of limbs we replace
	var/list/replacement_zones = list(
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/robot,
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/robot,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/robot,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/robot,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/robot,
	)

/datum/component/human_corruption/Initialize(datum/fleshmind_controller/incoming_controller)

	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

	our_controller = incoming_controller

	var/mob/living/carbon/human/infected_human = parent

	infected_human.fully_heal(TRUE)
	infected_human.heal_and_revive(0)

	to_chat(infected_human, span_hypnophrase("Your mind feels at ease, your mind feels one with the flesh."))
	to_chat(infected_human, span_userdanger("IMPORTANT INFO, MUST READ: [CONTROLLED_MOB_POLICY]"))

	RegisterSignal(infected_human, COMSIG_ATOM_UPDATE_OVERLAYS, .proc/update_parent_overlays)
	RegisterSignal(infected_human, COMSIG_PARENT_EXAMINE, .proc/on_examine)
	RegisterSignal(infected_human, COMSIG_ATOM_EMP_ACT, .proc/emp_act)
	RegisterSignal(infected_human, COMSIG_LIVING_DEATH, .proc/host_death)

	if(our_controller)
		for(var/obj/structure/fleshmind/structure/core/iterating_core in our_controller.cores)
			RegisterSignal(iterating_core, COMSIG_PARENT_QDELETING, .proc/core_death)

	// Action generation and granting
	for(var/iterating_action as anything in actions_to_give)
		var/datum/action/new_action = new iterating_action
		new_action.Grant(infected_human)
		granted_actions += new_action
		RegisterSignal(new_action, COMSIG_PARENT_QDELETING, .proc/action_destroyed)

	infected_human.faction |= FACTION_FLESHMIND

	ADD_TRAIT(infected_human, TRAIT_NOGUNS, "fleshmind")

	create_glow()

	infected_human.update_appearance()

/datum/component/human_corruption/Destroy(force, silent)
	QDEL_LIST(granted_actions)
	var/mob/living/parent_mob = parent
	parent_mob.faction -= FACTION_FLESHMIND
	UnregisterSignal(parent, list(
		COMSIG_ATOM_UPDATE_OVERLAYS,
		COMSIG_PARENT_EXAMINE,
		COMSIG_ATOM_EMP_ACT,
		COMSIG_LIVING_DEATH,
	))
	REMOVE_TRAIT(parent_mob, TRAIT_NOGUNS, "fleshmind")
	parent_mob.remove_filter("corruption_glow")
	parent_mob.update_appearance()
	return ..()

/datum/component/human_corruption/proc/update_parent_overlays(atom/source, list/new_overlays)
	SIGNAL_HANDLER

	new_overlays += mutable_appearance('modular_skyrat/modules/fleshmind/icons/hivemind_mobs.dmi', "human_overlay")

/datum/component/human_corruption/proc/action_destroyed(datum/action/deleting_action, force) // What why are we deleting!!
	SIGNAL_HANDLER
	if(QDELETED(deleting_action)) // Byond, dye.
		return

	granted_actions -= deleting_action

/datum/component/human_corruption/proc/on_examine(atom/examined, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += "<b>It has strange wires wrappped around it!</b>"

/datum/component/human_corruption/proc/core_death(obj/structure/fleshmind/structure/core/deleting_core, force)
	SIGNAL_HANDLER

	to_chat(parent, span_userdanger("Your mind screams as you feel a processor core dying!"))

/datum/component/human_corruption/proc/emp_act(datum/source, severity)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/parent_human = parent

	INVOKE_ASYNC(parent_human, /mob/proc/emote, "scream")
	parent_human.apply_status_effect(/datum/status_effect/jitter, 20 SECONDS)
	parent_human.Knockdown(10)
	to_chat(parent_human, span_userdanger("You feel your implants freeze up!"))

/datum/component/human_corruption/proc/host_death()
	SIGNAL_HANDLER

	qdel(src)

/datum/component/human_corruption/proc/create_glow()
	var/atom/movable/parent_movable = parent
	if (!istype(parent_movable))
		return

	parent_movable.add_filter("corruption_glow", 2, list("type" = "outline", "color" = FLESHMIND_LIGHT_BLUE, "size" = 2))
	addtimer(CALLBACK(src, .proc/start_glow_loop, parent_movable), rand(0.1 SECONDS, 1.9 SECONDS))

/datum/component/human_corruption/proc/start_glow_loop(atom/movable/parent_movable)
	var/filter = parent_movable.get_filter("corruption_glow")
	if (!filter)
		return

	animate(filter, alpha = 110, time = 1.5 SECONDS, loop = -1)
	animate(alpha = 40, time = 2.5 SECONDS)
