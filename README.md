# Half-Life: Zombie Escape

![Author](https://img.shields.io/badge/Author-rtxA-red) ![Version](https://img.shields.io/badge/Version-0.2-red) ![Last Update](https://img.shields.io/badge/Last%20Update-21/07/2020-red) [![Source Code](https://img.shields.io/badge/GitHub-Source%20Code-blueviolet)](https://github.com/rtxa/HL-Zombie-Escape)

## ☉ Description

HL Zombie escape is a mini-mod for Half-Life 1 based on the mod from CS 1.6/CSO. It's very fun and easy to play.

At the beginning all players will be frozen until the first infection. The zombies will be choseen randomly depending on how many players are in the server. After that, all humans have to run. Zombies are frozen and will be released after 15 seconds. Goal of team zombie is to catch and infect all humans. Goal of team human is to run and escape with sucess.

- Zombies have high health, but humans have weapons with a high knockback power.
- Depending of the map, humans can defend some places, break floors or close gates to delay the zombies.

Watch the video to discover more about it.

## ☰ Commands

### ☉ General

- sv_restart - Restart the game. Score of both teams are reset.
- sv_restartround - Restart the round.
- ze_round_time \<seconds> - Set round time. Default: *500*.
- ze_round_end_delay \<seconds> - Set delay for start a new round when round ends. Default: *6.0*.
- ze_release_time \<seconds> - Set time for release zombies. Default: *15*.
- ze_freeze_time \<seconds> - Set time for first infection. Default: *5.0*.
- ze_minplayers \<value> - Set minimum of players required to play a round. Default: *2*.

### ☉ Human

- ze_human_health \<value> - Default: *150*.
- ze_human_armour \<value> - Default: *0*.
- ze_human_maxspeed \<value> - Default: *300.0*.
- ze_human_kill_frags \<value> - Default: *3*.

### ☉ Zombie

- ze_zombie_health \<value> - Default: *5000*.
- ze_zombie_gravity \<value> - Default: *0.8*.
- ze_zombie_maxspeed \<value> - Default: *300.0*.
- ze_zombie_infect_frags \<value> - Default: *1*.

## ☰ Requirements

- [Last AMXX 1.9](https://www.amxmodx.org/downloads-new.php) or newer.
- [HL Restore Map API](https://forums.alliedmods.net/showthread.php?p=2705090)

## ⤓ Download

- **Source** package contains the source code of the game mode.
- **Full** package contains compiled plugins of the game mode with the resources and HL Restore Map API ready to use.

You can find **Full** package [here](https://github.com/rtxa/HL-Zombie-Escape/releases). **Source** can be found in the attachments.

Recommended **map** to play in this game mode: [ze_cave_v2_final](https://gamebanana.com/maps/194333)

## ⚙ Installation

1. __Download__ the attached files and __extract__ them in your server's folder (valve).
2. __Compile__ all the files and save them in your plugins folder.

Now you are __ready__ to play HL Zombie Escape. 

## ⛏ To Do

- ☐ Add fire and frost grenade.
- ☐ Respawn connecting players in the middle of the round as zombies, so they don't have to wait.

## ☉ Preview

https://www.youtube.com/watch?v=Gfbt3jTXmk0

## ⚛ Notes

- The mod has multi-language support. You can translate the plugin into any language editing hlze.txt file found in lang's folder.

Please, feel free to report any issues or give suggestions. Any feedback will be appreciated.
