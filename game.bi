'OHRRPGCE - game.bi
'(C) Copyright 1997-2006 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'Auto-generated by MAKEBI from game.bas

#IFNDEF GAME_BI
#DEFINE GAME_BI

#INCLUDE "game_udts.bi"

declare function valid_item_slot(item_slot as integer) as integer
declare function valid_item(itemid as integer) as integer
declare function valid_hero_party(who as integer, minimum as integer=0) as integer
declare function valid_menuslot(menuslot as integer) as integer
declare function valid_menuslot_and_mislot(menuslot as integer, mislot as integer) as integer
declare function valid_plotstr(n as integer) as integer
declare function valid_formation(form as integer) as integer
declare function valid_formation_slot(form as integer, slot as integer) as integer
declare function valid_zone(id as integer) as integer
declare function valid_tile_pos(x as integer, y as integer) as integer
declare sub loadmap_gmap(mapnum)
declare sub loadmap_npcl(mapnum)
declare sub loadmap_npcd(mapnum)
declare sub loadmap_tilemap(mapnum)
declare sub loadmap_passmap(mapnum)
declare sub loadmap_zonemap(mapnum)
declare sub loadmaplumps (mapnum, loadmask)
declare sub menusound(byval s as integer)
declare sub dotimer(byval l as integer)
declare function dotimerbattle() as integer
declare function dotimermenu() as integer
declare sub dotimerafterbattle()
declare function count_sav(filename as string) as integer
declare function add_menu (record as integer, allow_duplicate as integer=no) as integer
declare sub remove_menu (slot as integer, byval run_on_close as integer=YES)
declare sub bring_menu_forward (slot as integer)
declare function menus_allow_gameplay () as integer
declare function menus_allow_player () as integer
declare sub player_menu_keys (catx(), caty())
declare sub check_menu_tags ()
declare function game_usemenu (state as menustate) as integer
declare function find_menu_id (id as integer) as integer
declare function find_menu_handle (handle) as integer
declare function find_menu_item_handle_in_menuslot (handle as integer, menuslot as integer) as integer
declare function find_menu_item_handle (handle as integer, byref found_in_menuslot) as integer
declare function assign_menu_item_handle (byref mi as menudefitem) as integer
declare function assign_menu_handles (byref menu as menudef) as integer
declare function menu_item_handle_by_slot(menuslot as integer, mislot as integer, visible_only as integer=yes) as integer
declare function find_menu_item_slot_by_string(menuslot as integer, s as string, mislot as integer=0, visible_only as integer=yes) as integer
declare function allowed_to_open_main_menu () as integer
declare function random_formation (byval set as integer) as integer
declare sub init_default_text_colors()
DECLARE FUNCTION activate_menu_item(mi AS MenuDefItem, BYVAL menuslot AS INTEGER, BYVAL newcall AS INTEGER=YES) AS INTEGER
DECLARE SUB init_text_box_slices(txt AS TextBoxState)
DECLARE SUB cleanup_text_box ()
DECLARE SUB refresh_map_slice()
DECLARE SUB refresh_map_slice_tilesets()
DECLARE FUNCTION vehicle_is_animating() AS INTEGER
DECLARE SUB reset_vehicle(v AS vehicleState)
DECLARE SUB dump_vehicle_state()
DECLARE SUB usenpc(BYVAL cause AS INTEGER, BYVAL npcnum AS INTEGER)
DECLARE SUB sfunctions (BYVAL cmdid AS INTEGER)
DECLARE FUNCTION first_free_slot_in_party() AS INTEGER
DECLARE FUNCTION first_free_slot_in_active_party() AS INTEGER
DECLARE FUNCTION first_free_slot_in_reserve_party() AS INTEGER
DECLARE FUNCTION free_slots_in_party() AS INTEGER

#ENDIF
