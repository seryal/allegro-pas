PROGRAM ex_blit;
(*
 * An example demonstrating different blending modes.
 *
 * Lazarus forum user x2nie proposed the fix for Text 4.
 *)
(*
  Copyright (c) 2012-2020 Guillermo Martínez J.

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
 *)

{$IFDEF FPC}
  {$POINTERMATH ON}
  {$IFDEF WINDOWS}{$R 'manifest.rc'}{$ENDIF}
{$ENDIF}

USES
  Common,
  Allegro5, al5base, al5color, al5font, al5image, al5strings,
  math;

CONST
  FPS = 60;

VAR
  Pattern: ALLEGRO_BITMAPptr;
  Font: ALLEGRO_FONTptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;
  Background, TextClr, Black, Red: ALLEGRO_COLOR;
  Timer, Counter: ARRAY [1..4] OF DOUBLE;
  TextX, TextY: SINGLE;



  FUNCTION ExampleBitmap (CONST w, h: INTEGER): ALLEGRO_BITMAPptr;
  VAR
    i, j: INTEGER;
    mx, my, a, d, sat, hue: SINGLE;
    State: ALLEGRO_STATE;
    Lock: ALLEGRO_LOCKED_REGIONptr;
    Pattern: ALLEGRO_BITMAPptr;
  BEGIN
    mx := w * 0.5;
    my := h * 0.5;
    Pattern := al_create_bitmap (w, h);
    al_store_state (State, ALLEGRO_STATE_TARGET_BITMAP);
    al_set_target_bitmap (Pattern);
{ Ignore message:
ex_blit.pas(67,5) Note: Local variable "Lock" is assigned but never used
  It is initialized at "Init". }
    Lock := al_lock_bitmap (Pattern, ALLEGRO_PIXEL_FORMAT_ANY, ALLEGRO_LOCK_WRITEONLY);
    FOR i := 0 TO w - 1 DO
    BEGIN
      FOR j := 0 TO h - 1 DO
      BEGIN
	a := arctan2 (i - mx, j - my);
	d := sqrt (power (i - mx, 2) + power (j - my, 2));
	sat := power (1 - 1 / (1 + d * 0.1), 5);
	hue := 3 * a * 180 / ALLEGRO_PI;
	hue := (hue / 360 - floor (hue / 360)) * 360;
	al_put_pixel (i, j, al_color_hsv (hue, sat, 1))
      END
    END;
    al_put_pixel (0, 0, Black);
    al_unlock_bitmap (Pattern);
    al_restore_state (State);
    ExampleBitmap := Pattern
  END;



  PROCEDURE SetXY (CONST x, y: SINGLE);
  BEGIN
    TextX := x; TextY := y
  END;



  PROCEDURE GetXY (OUT x, y: SINGLE);
  BEGIN
    x := TextX; y := TextY
  END;



  PROCEDURE Print (CONST Fmt: AL_STR; CONST Args: ARRAY OF CONST);
  VAR
    th: INTEGER;
  BEGIN
    th := al_get_font_line_height (Font);
    al_set_blender (ALLEGRO_ADD, ALLEGRO_ONE, ALLEGRO_INVERSE_ALPHA);
    al_draw_text (Font, TextClr, TextX, TextY, 0, al_str_format (Fmt, Args));
    TextY := TextY + th
  END;



  PROCEDURE StartTimer (Ndx: INTEGER);
  BEGIN
    Timer[Ndx] := Timer[Ndx] - al_get_time;
    Counter[Ndx] := Counter[Ndx] + 1
  END;



  PROCEDURE StopTimer (Ndx: INTEGER);
  BEGIN
    Timer[Ndx] := Timer[Ndx] + al_get_time
  END;



  FUNCTION GetFPS  (Ndx: INTEGER): SINGLE;
  BEGIN
    IF Timer[Ndx] = 0 THEN EXIT (0.0);
    GetFPS := Counter[Ndx] / Timer[Ndx]
  END;



  PROCEDURE Draw;
  TYPE
    PByteArray = ^TByteArray;
    TByteArray = ARRAY [WORD] OF BYTE;
  VAR
    x, y: SINGLE;
    i, ix, iy, iw, ih, FormatSize: INTEGER;
    Screen, Temp: ALLEGRO_BITMAPptr;
    FormatLock: ALLEGRO_PIXEL_FORMAT;
    Lock: ALLEGRO_LOCKED_REGIONptr;
    BitmapData, ScreenData: PByteArray;
  BEGIN
    iw := al_get_bitmap_width (Pattern);
    ih := al_get_bitmap_height (Pattern);
    al_set_blender (ALLEGRO_ADD, ALLEGRO_ONE, ALLEGRO_ZERO);
    al_clear_to_color (Background);
    Screen := al_get_target_bitmap;

    SetXY (8, 8);

  { Test 1. }
  { /* Disabled: drawing to same bitmap is not supported. }
  (*
    Print ('Screen -> Screen (%.1f fps)', get_fps(0));
    get_xy(&x, &y);
    al_draw_bitmap(ex.Pattern, x, y, 0);

    start_timer(0);
    al_draw_bitmap_region(screen, x, y, iw, ih, x + 8 + iw, y, 0);
    stop_timer(0);
    SetXY (x, y + ih);
   *)

  { Test 2. }
    Print ('Screen -> Bitmap -> Screen (%.1f fps)', [GetFPS (1)]);
    GetXY (x, y);
    al_draw_bitmap (Pattern, x, y, 0);

    Temp := al_create_bitmap (iw, ih);
    al_set_target_bitmap (Temp);
    al_clear_to_color (Red);
    StartTimer (1);
    al_draw_bitmap_region (Screen, x, y, iw, ih, 0, 0, 0);

    al_set_target_bitmap (Screen);
    al_draw_bitmap (Temp, x + 8 + iw, y, 0);
    StopTimer (1);
    SetXY (x, y + ih);

    al_destroy_bitmap (Temp);

  { Test 3. }
    Print ('Screen -> Memory -> Screen (%.1f fps)', [GetFPS (2)]);
    GetXY (x, y);
    al_draw_bitmap (Pattern, x, y, 0);

    al_set_new_bitmap_flags (ALLEGRO_MEMORY_BITMAP);
    Temp := al_create_bitmap (iw, ih);
    al_set_target_bitmap (Temp);
    al_clear_to_color (Red);
    StartTimer (2);
    al_draw_bitmap_region (Screen, x, y, iw, ih, 0, 0, 0);

    al_set_target_bitmap (Screen);
    al_draw_bitmap (Temp, x + 8 + iw, y, 0);
    StopTimer (2);
    SetXY (x, y + ih);

    al_destroy_bitmap (Temp);
    al_set_new_bitmap_flags (ALLEGRO_VIDEO_BITMAP);


  { Test 4. }
    Print ('Screen -> Locked -> Screen (%.1f fps)', [GetFPS(3)]);
    GetXY (x, y);
    al_draw_bitmap (Pattern, x, y, 0);

    StartTimer (3);

    ix := Round (x); iy := Round (y);
    Lock := al_lock_bitmap_region (
      Screen,
      ix, iy, iw, ih,
      ALLEGRO_PIXEL_FORMAT_ANY, ALLEGRO_LOCK_READONLY
    );
    FormatLock := ALLEGRO_PIXEL_FORMAT (Lock.format);
    FormatSize := Lock.pixel_size;
    BitmapData := AllocMem (FormatSize * iw * ih);
    FOR i := 0 TO ih - 1 DO
    BEGIN
    { Lock.pitch may be negative (i.e. graphics card stores textures upside down)
      so indexes can't be used here as only positive values can be used.
      So use pointers.
    }
      ScreenData := Lock.Data + (i * Lock.pitch);
      move (
	ScreenData[0],
	BitmapData[i * FormatSize * iw],
	FormatSize * iw
      )
    END;
    al_unlock_bitmap (Screen);

    Lock := al_lock_bitmap_region (
      Screen,
      ix + 8 + iw, iy, iw, ih,
      FormatLock, ALLEGRO_LOCK_WRITEONLY
    );
    FOR i := 0 TO ih - 1 DO
    BEGIN
      ScreenData := Lock.Data + (i * Lock.pitch);
      move (
	BitmapData[i * FormatSize * iw],
	ScreenData[0],
	FormatSize * iw
      )
    END;
    al_unlock_bitmap (Screen);
    FreeMem (BitmapData);

    StopTimer (3);
    SetXY (x, y + ih)
  END;



  PROCEDURE Tick;
  BEGIN
    Draw;
    al_flip_display
  END;



  PROCEDURE Run;
  VAR
    Event: ALLEGRO_EVENT;
    NeedDraw: BOOLEAN;
  BEGIN
    NeedDraw := TRUE;

    REPEAT
      IF NeedDraw AND al_is_event_queue_empty (EventQueue) THEN
      BEGIN
        Tick;
        NeedDraw := FALSE
      END;
      al_wait_for_event (EventQueue, @Event);
      CASE Event.ftype OF
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        EXIT;
      ALLEGRO_EVENT_KEY_DOWN:
        IF Event.keyboard.keycode = ALLEGRO_KEY_ESCAPE THEN EXIT;
      ALLEGRO_EVENT_TIMER:
        NeedDraw := TRUE;
      END
    UNTIL FALSE
  END;



  PROCEDURE Init;
  BEGIN
    Font := al_load_font ('data/fixed_font.tga', 0, 0);
    IF Font = NIL THEN
      AbortExample ('data/fixed_font.tga not found');
    Background := al_color_name ('beige');
    TextClr := al_color_name ('black');
    Black := al_color_name ('black');
    Red := al_map_rgba_f (1, 0, 0, 1);
    Pattern := ExampleBitmap (100, 100)
  END;



VAR
  Display: ALLEGRO_DISPLAYptr;
  TheTimer: ALLEGRO_TIMERptr;
BEGIN
  IF NOT al_init THEN AbortExample ('Could not init Allegro.');

  al_install_keyboard;
  al_init_image_addon;
  al_init_font_addon;

  Display := al_create_display (640, 480);
  IF Display = NIL THEN AbortExample ('Could not create display');

  Init;

  TheTimer := al_create_timer (1 / FPS);

  EventQueue := al_create_event_queue;
  al_register_event_source (EventQueue, al_get_keyboard_event_source);
  al_register_event_source (EventQueue, al_get_display_event_source (Display));
  al_register_event_source (EventQueue, al_get_timer_event_source (TheTimer));

  al_start_timer (TheTimer);
  Run;

  al_destroy_event_queue (EventQueue)
END.
