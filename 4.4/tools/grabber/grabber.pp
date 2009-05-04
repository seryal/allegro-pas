PROGRAM grabber;
(*______   ___    ___
 /\  _  \ /\_ \  /\_ \
 \ \ \L\ \\//\ \ \//\ \      __     __   _ __   ___        __    ___      ____
  \ \  __ \ \ \ \  \ \ \   /'__`\ /'_ `\/\`'__\/ __`\    /'__`\ /\__`\  /'___/
   \ \ \/\ \ \_\ \_ \_\ \_/\  __//\ \L\ \ \ \//\ \L\ \__/\ \L\ \\/ __ \/\____`\
    \ \_\ \_\/\____\/\____\ \____\ \____ \ \_\\ \____/\_\ \  __//\____/\/\____/
     \/_/\/_/\/____/\/____/\/____/\/___L\ \/_/ \/___/\/_/\ \ \/ \/___/  \/___/
                                    /\____/               \ \_\
                                    \_/__/                 \/_/

 Helper application.  Creates and modifies DATA files you can load in your game
 using al_load_datafile. *)

USES
  main,
  allegro, algui,
  sysutils;



(* Initialization. *)
  FUNCTION Initialize: BOOLEAN;
  VAR
    Bpp, W, H: INTEGER;
  BEGIN
    Initialize := FALSE;
  { We'll use good old 7bit ASCII. }
    al_set_uformat (AL_U_ASCII);
    IF NOT al_init THEN
    BEGIN
      WriteLn ('Can'' initialize Allegro!');
      EXIT;
    END;
    al_install_timer;
    al_install_keyboard;
  { Try to use the same depth color as the desktop. }
    Bpp := al_desktop_color_depth;
    IF Bpp = 0 THEN
      Bpp := 8;
  { Don't be bigger than desktop. }
    IF NOT al_get_desktop_resolution (W, H) THEN
    BEGIN
      W := 800; H := 600;
    END;
    IF (W > 800) AND (H > 600) THEN
    BEGIN
      W := 800; H := 600;
    END;
    al_set_color_depth (Bpp);
    IF NOT al_set_gfx_mode (AL_GFX_AUTODETECT_WINDOWED, W, H, 0, 0) THEN
      IF NOT al_set_gfx_mode (AL_GFX_AUTODETECT, W, H, 0, 0) THEN
      BEGIN
	al_message ('Can''t set a graphic mode!');
	EXIT;
      END;
    al_set_window_title ('Grabber');
  { Mouse is optional. }
    IF al_install_mouse > 0 THEN
    BEGIN
    { Try hardware cursor, if available. }
      al_enable_hardware_cursor;
      al_select_mouse_cursor (AL_MOUSE_CURSOR_ARROW);
      al_show_mouse (al_screen);
    END;
  { I know, we aren't set up sound. }
  { Everything is Ok. }
    Initialize := TRUE;
  END;



BEGIN
  IF Initialize THEN
  TRY
    main.Create;
    al_do_dialog (main.Dialog, -1);
  EXCEPT
  { Catches mad exceptions. }
    ON E: Exception DO
    BEGIN
      al_message (E.message);
    END;
  END;
  al_exit;
END.
