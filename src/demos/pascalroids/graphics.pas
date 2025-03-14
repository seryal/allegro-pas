unit Graphics;
(* Implements some graphics stuff. *)
(*
  Copyright (c) 2024 Guillermo Martínez J.

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

{$IFDEF FPC}{$MODESWITCH ADVANCEDRECORDS+}{$ENDIF}

interface

  uses
    Sprites,
    Allegro5, al5base, al5primitives;

  const
  (* Max number of vertex. *)
    MaxVertices = 10;

  type
  (* A simple polygon. *)
    PPolygon = ^TPolygon;
    TPolygon = record
    private
      Vertices: array [0.. MaxVertices - 1] of ALLEGRO_VERTEX;
      NumVertices: Integer;
      fColor: ALLEGRO_COLOR;

    (* Set color to polygon vertices. *)
      procedure SetColor (aColor: ALLEGRO_COLOR);
    public
    (* Initialize the polygon.  Should be called before add vertices. *)
      procedure Reset;
    (* Add a vertex. *)
      procedure AddVertex (const aX, aY: AL_FLOAT);
    (* Draw the polygon. *)
      procedure Draw;

      property Color: ALLEGRO_COLOR read fColor write SetColor;
    end;



  (* A sprite that uses a polygon. *)
    TSpritePolygon = class (TSprite)
    private
      fPolygon: PPolygon;
      fScale, fAngle: Single;
    public
    (* Constructor. *)
      constructor Create; override;
    (* Draw the sprite. *)
      procedure Draw; override;

    (* Pointer to the polygon to use. *)
      property Polygon: PPolygon read fPolygon write fPolygon;
    (* Image scale. *)
      property Scale: Single read fScale write fScale;
    (* Rotation angle in radians. *)
      property Angle: Single read fAngle write fAngle;
    end;

  var
  (* Some colors. *)
    clrWhite, clrBlack,
    clrGreen, clrRed, clrBlue: ALLEGRO_COLOR;

(* Initialize the unit.  Should be called after create the display. *)
  procedure Initialize;

implementation

  var
    fIdentity: ALLEGRO_TRANSFORM;

  procedure Initialize;
  begin
    al_init_primitives_addon;
    clrBlack := al_map_rgb (  0,   0,   0);
    clrGreen := al_map_rgb (  0, 255,   0);
    clrRed   := al_map_rgb (255,   0,   0);
    clrBlue  := al_map_rgb (  0, 102, 255);
    clrWhite := al_map_rgb (255, 255, 255);
    al_identity_transform (fIdentity)
  end;



(*
 * TPolygon
 ************************************************************************)

  procedure TPolygon.SetColor (aColor: ALLEGRO_COLOR);
  var
    lNdx: Integer;
  begin
    for lNdx := 0 to (MaxVertices - 1) do
      Self.Vertices[lNdx].color := aColor
  end;



  procedure TPolygon.Reset;
  begin
    Self.SetColor (clrWhite);
    Self.NumVertices := 0
  end;



  procedure TPolygon.AddVertex (const aX, aY: AL_FLOAT);
  begin
  {$IFDEF DEBUG}
    if (0 > Self.NumVertices) or (Self.NumVertices > MaxVertices )then
      raise Exception.Create ('Polygon wasn''t reset!')
    else
  {$ENDIF}
    if Self.NumVertices < MaxVertices then
    begin
      Self.Vertices[Self.NumVertices].x := aX + 0.5;
      Self.Vertices[Self.NumVertices].y := aY + 0.5;
      Inc (Self.NumVertices)
    end
  end;



  procedure TPolygon.Draw;
  begin
    al_draw_prim (
      Self.Vertices, Nil,
      0, Self.NumVertices,
      ALLEGRO_PRIM_LINE_LOOP
    )
  end;



(*
 * TSpritePolygon
 ************************************************************************)

  constructor TSpritePolygon.Create;
  begin
    inherited Create;
    fPolygon := Nil;
    fAngle := 0;
    fScale := 1
  end;



  procedure TSpritePolygon.Draw;
  var
    lMatrix: ALLEGRO_TRANSFORM;
  begin
    al_build_transform (
      lMatrix,
      Self.X, Self.Y, Self.Scale, Self.Scale, Self.Angle
    );
    al_use_transform (lMatrix);
    fPolygon^.Draw;
    al_use_transform (fIdentity); { Safe drawing. }
{$IfDef DEBUGMODE}
    al_draw_circle (Self.X ,Self.Y, Self.Radius, clrBlue, 1);
{$EndIf}
  end;

end.

