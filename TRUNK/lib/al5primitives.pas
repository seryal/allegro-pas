UNIT al5primitives;
(*<Primitive drawing.

  @bold(Warning:)  Some parts of this add-on don't work correctly.  See the
  examples to know what primitives work and what ones don't.  Note also that
  use of the primitives that doesn't work may result in memory corruption and
  kill your program (and may be your operating system too!).  Of course,
  @bold(this unit will work perfectly in the next stable version).

@bold(High level drawing routines)

  High level drawing routines encompass the most common usage of this addon: to
  draw geometric primitives, both smooth (variations on the circle theme) and
  piecewise linear. Outlined primitives support the concept of thickness with
  two distinct modes of output: hairline lines and thick lines. Hairline lines
  are specifically designed to be exactly a pixel wide, and are commonly used
  for drawing outlined figures that need to be a pixel wide. Hairline thickness
  is designated as thickness less than or equal to 0. Unfortunately, the exact
  rasterization rules for drawing these hairline lines vary from one video card
  to another, and sometimes leave gaps where the lines meet. If that matters to
  you, then you should use thick lines. In many cases, having a thickness of 1
  will produce 1 pixel wide lines that look better than hairline lines.
  Obviously, hairline lines cannot replicate thicknesses greater than 1. Thick
  lines grow symmetrically around the generating shape as thickness is
  increased.

@bold(Pixel-precise output)

  While normally you should not be too concerned with which pixels are
  displayed when the high level primitives are drawn, it is nevertheless
  possible to control that precisely by carefully picking the coordinates at
  which you draw those primitives.

  To be able to do that, however, it is critical to understand how GPU cards
  convert shapes to pixels. Pixels are not the smallest unit that can be
  addressed by the GPU. Because the GPU deals with floating point coordinates,
  it can in fact assign different coordinates to different parts of a single
  pixel. To a GPU, thus, a screen is composed of a grid of squares that have
  width and length of 1. The top left corner of the top left pixel is located
  at (0, 0). Therefore, the center of that pixel is at (0.5, 0.5). The basic
  rule that determines which pixels are associated with which shape is then as
  follows: a pixel is treated to belong to a shape if the pixel's center is
  located in that shape. The figure below illustrates the above concepts:

[Diagram showing a how pixel output is calculated by the GPU given the mathematical description of several shapes.]

  This figure depicts three shapes drawn at the top left of the screen: an
  orange and green rectangles and a purple circle. On the left are the
  mathematical descriptions of pixels on the screen and the shapes to be drawn.
  On the right is the screen output. Only a single pixel has its center inside
  the circle, and therefore only a single pixel is drawn on the screen.
  Similarly, two pixels are drawn for the orange rectangle. Since there are no
  pixels that have their centers inside the green rectangle, the output image
  has no green pixels.

  Here is a more practical example. The image below shows the output of this code:
@longcode(#
/* blue vertical line */
al_draw_line(0.5, 0, 0.5, 6, color_blue, 1);
/* red horizontal line */
al_draw_line(2, 1, 6, 1, color_red, 2);
/* green filled rectangle */
al_draw_filled_rectangle(3, 4, 5, 5, color_green);
/* purple outlined rectangle */
al_draw_rectangle(2.5, 3.5, 5.5, 5.5, color_purple, 1);
#)

[Diagram showing a practical example of pixel output resulting from the invocation of several primitives addon functions.]

  It can be seen that lines are generated by making a rectangle based on the
  dashed line between the two endpoints. The thickness causes the rectangle to
  grow symmetrically about that generating line, as can be seen by comparing
  the red and blue lines. Note that to get proper pixel coverage, the
  coordinates passed to the al_draw_line had to be offset by 0.5 in the
  appropriate dimensions.

  Filled rectangles are generated by making a rectangle between the endpoints
  passed to the @link(al_draw_filled_rectangle).

  Outlined rectangles are generated by symmetrically expanding an outline of a
  rectangle. With a thickness of 1, as depicted in the diagram, this means that
  an offset of 0.5 is needed for both sets of endpoint coordinates to exactly
  line up with the pixels of the display raster.

  The above rules only apply when multisampling is turned off. When
  multisampling is turned on, the area of a pixel that is covered by a shape is
  taken into account when choosing what color to draw there. This also means
  that shapes no longer have to contain the pixel's center to affect its color.
  For example, the green rectangle in the first diagram may in fact be drawn as
  two (or one) semi-transparent pixels. The advantages of multisampling is that
  slanted shapes will look smoother because they will not have jagged edges. A
  disadvantage of multisampling is that it may make vertical and horizontal
  edges blurry. While the exact rules for multisampling are unspecified, and
  may vary from GPU to GPU, it is usually safe to assume that as long as a
  pixel is either completely covered by a shape or completely not covered, then
  the shape edges will be sharp. The offsets used in the second diagram were
  chosen so that this is the case: if you use those offsets, your shapes (if
  they are oriented the same way as they are on the diagram) should look the
  same whether multisampling is turned on or off. *)
(* Copyright (c) 2012-2016 Guillermo Martínez J.

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

{$include allegro5.cfg}

INTERFACE

  USES
    Allegro5, al5base;
  CONST
  (* Builds library name. *)
    { @exclude }
    ALLEGRO_PRIMITIVES_LIB_NAME = _A5_LIB_PREFIX_+'allegro_primitives'+_DBG_+_A5_LIB_EXT_;

  TYPE
    ALLEGRO_PRIM_TYPE = (
      ALLEGRO_PRIM_LINE_LIST,
      ALLEGRO_PRIM_LINE_STRIP,
      ALLEGRO_PRIM_LINE_LOOP,
      ALLEGRO_PRIM_TRIANGLE_LIST,
      ALLEGRO_PRIM_TRIANGLE_STRIP,
      ALLEGRO_PRIM_TRIANGLE_FAN,
      ALLEGRO_PRIM_POINT_LIST,
      ALLEGRO_PRIM_NUM_TYPES
    );



    ALLEGRO_PRIM_ATTR = (
      ALLEGRO_PRIM_ATTR_NONE = 0,
      ALLEGRO_PRIM_POSITION = 1,
      ALLEGRO_PRIM_COLOR_ATTR,
      ALLEGRO_PRIM_TEX_COORD,
      ALLEGRO_PRIM_TEX_COORD_PIXEL,
      ALLEGRO_PRIM_ATTR_NUM
    );



    ALLEGRO_PRIM_STORAGE = (
      ALLEGRO_PRIM_FLOAT_2,
      ALLEGRO_PRIM_FLOAT_3,
      ALLEGRO_PRIM_SHORT_2
    );

  CONST
    ALLEGRO_PRIM_STORAGE_NONE = ALLEGRO_PRIM_FLOAT_2;
    ALLEGRO_VERTEX_CACHE_SIZE = 256;



    ALLEGRO_PRIM_QUALITY = 10;

  TYPE
    ALLEGRO_VERTEX_ELEMENTptr = ^ALLEGRO_VERTEX_ELEMENT;
    ALLEGRO_VERTEX_ELEMENT = RECORD
      attribute: ALLEGRO_PRIM_ATTR;
      storage: ALLEGRO_PRIM_STORAGE;
      offset: AL_INT;
    END;


  (* A vertex declaration. This opaque structure is responsible for describing
     the format and layout of a user defined custom vertex. It is created and
     destroyed by specialized functions.
     @seealso(al_create_vertex_decl) @seealso(al_destroy_vertex_decl)
     @seealso(ALLEGRO_VERTEX_ELEMENT) *)
    ALLEGRO_VERTEX_DECLptr = AL_POINTER;


    ALLEGRO_VERTEXptr = ^ALLEGRO_VERTEX;
    ALLEGRO_VERTEX = RECORD
      x, y, z: AL_FLOAT;
      u, v: AL_FLOAT;
      color: ALLEGRO_COLOR;
    END;



  (* A GPU vertex buffer that you can use to store vertices on the GPU instead
     of uploading them afresh during every drawing operation.
     @seealso(al_create_vertex_buffer) @seealso(al_destroy_vertex_buffer) *)
    ALLEGRO_VERTEX_BUFFERptr = AL_POINTER;
  (* A GPU index buffer that you can use to store indices of vertices in a
     vertex buffer on the GPU instead of uploading them afresh during every
     drawing operation.
     @seealso(al_create_index_buffer) @seealso(al_destroy_index_buffer) *)
    ALLEGRO_INDEX_BUFFERptr = AL_POINTER;


    ALLEGRO_EMIT_TRIANGLE_PROC = PROCEDURE (a, b, c: AL_INT; p: AL_VOIDptr);

    ALLEGRO_INIT_TRIANGLE_PROC = PROCEDURE (state: AL_UINTPTR_T; v1, v2, v3: ALLEGRO_VERTEXptr); CDECL;
    ALLEGRO_FIRST_TRIANGLE_PROC = PROCEDURE (state: AL_UINTPTR_T; x, y, l1, l2: AL_INT); CDECL;
    ALLEGRO_DRAW_TRIANGLE_PROC = PROCEDURE (state: AL_UINTPTR_T; x1, y, x2: AL_INT); CDECL;

    ALLEGRO_FIRST_LINE_PROC = PROCEDURE (state: AL_UINTPTR_T; px, py: AL_INT; v1, v2: ALLEGRO_VERTEXptr); CDECL;
    ALLEGRO_DRAW_LINE_PROC = PROCEDURE (state: AL_UINTPTR_T; x, y: AL_INT); CDECL;

    ALLEGRO_STEP_PROC = PROCEDURE (state: AL_UINTPTR_T; _type: AL_INT); CDECL;

    ALLEGRO_SPLINE_CONTROL_POINTS = ARRAY [0..7] OF AL_FLOAT;

(* Returns the (compiled) version of the addon, in the same format as
   @link(al_get_allegro_version). *)
  FUNCTION al_get_allegro_primitives_version: AL_UINT32;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
(* Initializes the primitives addon.
   @returns(@true on success, @false on failure.)
   @seealso(al_shutdown_primitives_addon) *)
  FUNCTION al_init_primitives_addon: AL_BOOL;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
(* Shut down the primitives addon.  This is done automatically at program exit,
   but can be called any time the user wishes as well.
   @seealso(al_init_primitives_addon) *)
  PROCEDURE al_shutdown_primitives_addon;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
(* Draws a subset of the passed vertex array.

   For example to draw a textured triangle you could use:
@longcode(#
ALLEGRO_COLOR white = al_map_rgb_f(1, 1, 1);
ALLEGRO_VERTEX v[] = {
   {.x = 128, .y = 0, .z = 0, .color = white, .u = 128, .v = 0},
   {.x = 0, .y = 256, .z = 0, .color = white, .u = 0, .v = 256},
   {.x = 256, .y = 256, .z = 0, .color = white, .u = 256, .v = 256}};
al_draw_prim(v, NULL, texture, 0, 3, ALLEGRO_PRIM_TRIANGLE_LIST);
#)
   @param(vtxs An array of vertices.)
   @param(texture Texture to use, pass @nil to use only color shaded primitves.)
   @param(decl Pointer to a vertex declaration. If set to @nil, the vertices
     are assumed to be of the @code(ALLEGRO_VERTEX) type.)
   @param(start Start index of the subset of the vertex array to draw.)
   @param(end One past the last index of the subset of the vertex array to draw.)
   @param(_type A member of the @code(ALLEGRO_PRIM_TYPE) enumeration, specifying
     what kind of primitive to draw.)
   @return(Number of primitives drawn.)
   @seealso(ALLEGRO_VERTEX) @seealso(ALLEGRO_PRIM_TYPE)
   @seealso(ALLEGRO_VERTEX_DECL) @seealso(al_draw_indexed_prim) *)
  FUNCTION al_draw_prim (VAR vtxs: ARRAY OF ALLEGRO_VERTEX; CONST decl: ALLEGRO_VERTEX_DECLptr; texture: ALLEGRO_BITMAPptr; start, finish: AL_INT; _type: ALLEGRO_PRIM_TYPE): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_draw_indexed_prim (CONST vtxs: AL_VOIDptr; CONST decl: ALLEGRO_VERTEX_DECLptr; texture: ALLEGRO_BITMAPptr; VAR indices: ARRAY OF AL_INT; num_vtx: AL_INT; _type: ALLEGRO_PRIM_TYPE): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_draw_vertex_buffer (vertex_buffer: ALLEGRO_VERTEX_BUFFERptr; texture: ALLEGRO_BITMAPptr; start, finish: AL_INT; _type: ALLEGRO_PRIM_TYPE): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_draw_indexed_buffer (vertex_buffer: ALLEGRO_VERTEX_BUFFERptr; texture: ALLEGRO_BITMAPptr; index_buffer: ALLEGRO_INDEX_BUFFERptr; start, finish: AL_INT; _type: ALLEGRO_PRIM_TYPE): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



(* Creates a vertex declaration, which describes a custom vertex format.
   @param(elements An array of ALLEGRO_VERTEX_ELEMENT structures.)
   @param(stride Size of the custom vertex structure.)
   @returns(Newly created vertex declaration.)
   @seealso(ALLEGRO_VERTEX_ELEMENT) @seealso(ALLEGRO_VERTEX_DECL)
   @seealso(al_destroy_vertex_decl) *)
  FUNCTION al_create_vertex_decl (VAR elements: ARRAY OF ALLEGRO_VERTEX_ELEMENT; stride: AL_INT): ALLEGRO_VERTEX_DECLptr;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
(* Destroys a vertex declaration.
   @seealso(ALLEGRO_VERTEX_ELEMENT) @seealso(ALLEGRO_VERTEX_DECL)
   @seealso(al_create_vertex_decl) *)
  PROCEDURE al_destroy_vertex_decl (decl: ALLEGRO_VERTEX_DECLptr);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  FUNCTION al_create_vertex_buffer (decl: ALLEGRO_VERTEX_DECLptr; const initial_data: AL_VOIDptr; num_vertices, flags: AL_INT): ALLEGRO_VERTEX_BUFFERptr;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_destroy_vertex_buffer (buffer: ALLEGRO_VERTEX_BUFFERptr);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_lock_vertex_buffer (buffer: ALLEGRO_VERTEX_BUFFERptr; offset, length, flags: AL_INT): AL_VOIDptr;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_unlock_vertex_buffer (buffer: ALLEGRO_VERTEX_BUFFERptr);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_get_vertex_buffer_size (buffer: ALLEGRO_VERTEX_BUFFERptr): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  FUNCTION al_create_index_buffer (decl: ALLEGRO_VERTEX_DECLptr; const initial_data: AL_VOIDptr; num_indices, flags: AL_INT): ALLEGRO_INDEX_BUFFERptr;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_destroy_index_buffer (buffer: ALLEGRO_INDEX_BUFFERptr);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_lock_index_buffer (buffer: ALLEGRO_INDEX_BUFFERptr; offset, length, flags: AL_INT): AL_VOIDptr;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_unlock_index_buffer (buffer: ALLEGRO_INDEX_BUFFERptr);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  FUNCTION al_get_index_buffer_size (buffer: ALLEGRO_INDEX_BUFFERptr): AL_INT;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  FUNCTION al_triangulate_polygon (CONST vertices: AL_FLOATptr; svertex_stride: AL_SIZE_T; CONST vertex_counts: AL_INTptr; emit_triangle: ALLEGRO_EMIT_TRIANGLE_PROC; userdata: AL_VOIDptr): AL_BOOL;
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



(* Custom primitives *)
  PROCEDURE al_draw_soft_triangle (v1, v2, v3: ALLEGRO_VERTEXptr; state: AL_UINTPTR_T; init: ALLEGRO_INIT_TRIANGLE_PROC; first: ALLEGRO_FIRST_TRIANGLE_PROC; step: ALLEGRO_STEP_PROC; draw: ALLEGRO_DRAW_TRIANGLE_PROC);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_soft_line (v1, v2: ALLEGRO_VERTEXptr; state: AL_UINTPTR_T; first: ALLEGRO_FIRST_LINE_PROC; step: ALLEGRO_STEP_PROC; draw: ALLEGRO_DRAW_LINE_PROC);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



(* Draws a line segment between two points.
   @param(x1, y1, x2, y2 Start and end points of the line.)
   @param(color Color of the line.)
   @param(thickness Thickness of the line, pass <= 0 to draw hairline lines.)
   @seealso(al_draw_soft_line) *)
  PROCEDURE al_draw_line (x1, y1, x2, y2: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
(* Draws an outlined triangle.
   @param(x1, y1, x2, y2, x3, y3 Three points of the triangle.)
   @param(color Color of the triangle.)
   @param(thickness Thickness of the lines, pass <= 0 to draw hairline lines.)
   @seealso(al_draw_filled_triangle) @seealso(al_draw_soft_triangle) *)
  PROCEDURE al_draw_triangle (x1, y1, x2, y2, x3, y3: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_rectangle (x1, y1, x2, y2: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_rounded_rectangle (x1, y1, x2, y2, rx, ry: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



(* When @code(thickness <= 0) this function computes positions of
   @code(num_points) regularly spaced points on an elliptical arc.  When
   @code(thickness > 0) this function computes two sets of points, obtained as
   follows: the first set is obtained by taking the points computed in the
   @code(thickness <= 0) case and shifting them by @code(thickness / 2)
   outward, in a direction perpendicular to the arc curve. The second set is
   the same, but shifted @code(thickness / 2) inward relative to the arc. The
   two sets of points are interleaved in the destination buffer (i.e. the first
   pair of points will be collinear with the arc center, the first point of the
   pair will be farther from the center than the second point; the next pair
   will also be collinear, but at a different angle and so on).

   The destination buffer @code(dest) is interpreted as a set of regularly
   spaced pairs of floats, each pair holding the coordinates of the
   corresponding point on the arc. The two floats in the pair are adjacent, and
   the distance (in bytes) between the addresses of the first float in two
   successive pairs is stride. For example, if you have a tightly packed array
   of floats with no spaces between pairs, then stride will be exactly
   @code(2 * sizeof (AL_FLOAT)).
   @param(dest The destination buffer.)
   @param(stride Distance @(in bytes@) between starts of successive pairs of
     points.)
   @param(cx, cy Center of the arc.)
   @param(rx, ry Radii of the arc.)
   @param(start_theta The initial angle from which the arc is calculated in
     radians.)
   @param(delta_theta Angular span of the arc in radians @(pass a negative
     number to switch direction@).)
   @param(thickness Thickness of the arc.)
   @param(num_points The number of points to calculate.)
   @seealso(al_draw_arc) @param(al_calculate_spline)
   @param(al_calculate_ribbon) *)
  PROCEDURE al_calculate_arc (dest: AL_FLOATptr; stride: AL_INT; cx, cy, rx, ry, start_theta, delta_theta, thickness: AL_FLOAT; num_segments: AL_INT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_circle (cx, cy, r: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_ellipse (cx, cy, rx, ry: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_arc (cx, cy, r, start_theta, delta_theta: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_elliptical_arc (cx, cy, rx, ry, start_theta, delta_theta: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_pieslice (cx, cy, r, start_theta, fdelta_theta: AL_FLOAT; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  PROCEDURE al_calculate_spline (dest: AL_FLOATptr; stride: AL_INT; VAR points: ALLEGRO_SPLINE_CONTROL_POINTS; thickness: AL_FLOAT; num_segments: AL_INT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_spline (VAR points: ALLEGRO_SPLINE_CONTROL_POINTS; color: ALLEGRO_COLOR; thickness: AL_FLOAT);
    CDECL;EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  PROCEDURE al_calculate_ribbon (dest: AL_FLOATptr; dest_stride: AL_INT; VAR points: ARRAY OF AL_FLOAT; points_stride: AL_INT; thickness: AL_FLOAT; num_segments: AL_INT);
    CDECL;EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_ribbon (VAR points: ARRAY OF AL_FLOAT; points_stride: AL_INT; color: ALLEGRO_COLOR; thickness: AL_FLOAT; num_segments: AL_INT);
    CDECL;EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



(* Draws a filled triangle.
   @Param(x1, y1, x2, y2, x3, y3 Three points of the triangle.)
   @param(color Color of the triangle.)
   @seealso(al_draw_triangle) *)
  PROCEDURE al_draw_filled_triangle (x1, y1, x2, y2, x3, y3: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_rectangle (x1, y1, x2, y2: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_ellipse (cx, cy, rx, ry: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_circle (cx, cy, r: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_pieslice (cx, cy, r, start_theta, fdelta_theta: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_rounded_rectangle (x1, y1, x2, y2, rx, ry: AL_FLOAT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  PROCEDURE al_draw_polyline (CONST vertices: AL_FLOATptr; vertex_stride, vertex_count, join_style, cap_style: AL_INT; color: ALLEGRO_COLOR; thickness, miter_limit: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;



  PROCEDURE al_draw_polygon (CONST vertices: AL_FLOATptr; vertex_count, join_style: AL_INT; color: ALLEGRO_COLOR; thickness, miter_limit: AL_FLOAT);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_polygon (CONST vertices: AL_FLOATptr; vertex_count: AL_INT; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;
  PROCEDURE al_draw_filled_polygon_with_holes (CONST vertices: AL_FLOATptr; CONST vertex_counts: AL_INTptr; color: ALLEGRO_COLOR);
    CDECL; EXTERNAL ALLEGRO_PRIMITIVES_LIB_NAME;

IMPLEMENTATION

END.
