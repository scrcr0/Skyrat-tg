/mob/living/basic/trstu
	icon = 'modular_skyrat/modules/trstu_content/icons/trstu_mobs.dmi'
	combat_mode = TRUE
	status_flags = NONE //don't inherit standard basicmob flags
	mob_size = MOB_SIZE_LARGE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	faction = list(FACTION_MINING)
	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY
	// Pale purple, should be red enough to see stuff on lavaland
	lighting_cutoff_red = 25
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 35
	/// Message to output if throwing damage is absorbed
	var/throw_blocked_message = "bounces off"

/mob/living/basic/trstu/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_SNOWSTORM_IMMUNE), INNATE_TRAIT)
