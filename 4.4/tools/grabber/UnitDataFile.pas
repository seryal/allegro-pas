UNIT UnitDataFile;
(*< Defines a class that expands Allegro's AL_DATAFILE struct making it easer to
    edit. *)
{$mode objfpc}{$H+}

INTERFACE

USES
  sysutils, Classes,
  alfile;



TYPE
(* Encapsulates and expands Allegro's AL_DATAFILE_OBJECT helping edition. *)
  TDataFileItem = CLASS
  PRIVATE
  (* List of properties. *)
    fProperties: TStringList;
  (* Identifies data type.  It's a 32 integer value returned by AL_ID function. *)
    fObjectType: LONGINT;
  (* Data of the object. *)
    fData: POINTER; fSize: LONGINT;
  PUBLIC
  (* Constructor. *)
    CONSTRUCTOR Create (aObject: AL_DATAFILE_OBJECTptr);
  (* Destructor. *)
    DESTRUCTOR Destroy; OVERRIDE;
  (* Returns TRUE if property exists. *)
    FUNCTION HasProperty (Name: STRING): BOOLEAN;
  (* Returns a property. *)
    FUNCTION GetProperty (Name: STRING): STRING;
  (* Creates or modifies a property. *)
    PROCEDURE SetProperty (Name, Value: STRING);
  (* Returns the datatype name. *)
    FUNCTION ObjectTypeName: STRING;
  (* Returns the object name. *)
    FUNCTION Name: STRING;

  (* Returns the data type identifier.  It's a 32 integer value returned by
     AL_ID function. *)
    PROPERTY ObjectType: LONGINT READ fObjectType;
  (* Data object. *)
    PROPERTY Data: POINTER READ fData;
  END;



(* Callbacks. *)
  TCallbackProcedure = PROCEDURE;
  TCallbackPrepareProcedure = PROCEDURE (num: INTEGER);
(* Class that encapsulates and expands Allegro's AL_DATAFILE. *)
  TDataFile = CLASS
  PRIVATE
  (* Stores the datafile.  Note it isn't a pointer to make edition more easy. *)
    fData: ARRAY [0..1023] OF TDataFileItem;
  (* To know if it was modified. *)
    fModified: BOOLEAN;
  (* Number of objects inserted. *)
    fCount: INTEGER;
  (* Callbacks. *)
    fPreLoadCallback, fPreSaveCallback: TCallbackPrepareProcedure;
    fLoadCallback, fSaveCallback: TCallbackProcedure;

    FUNCTION GetItem (Ndx: INTEGER): TDataFileItem;
  PUBLIC
  (* Constructor. *)
    CONSTRUCTOR Create;
  (* Destructor. *)
    DESTRUCTOR Destroy; OVERRIDE;
  (* Cleans the file. *)
    PROCEDURE Clean;
  (* Loads the datafile. *)
    PROCEDURE LoadFrom (FileName: STRING);
  (* Saves the datafile. *)
    PROCEDURE SaveTo (Filename: STRING);

  (* Returns true if it was modified. *)
    PROPERTY Modified: BOOLEAN READ fModified;
  (* This callback is called before load a file.  'num' is num of objects. *)
    PROPERTY PreLoadCallback: TCallbackPrepareProcedure WRITE fPreLoadCallback;
  (* This callback is called for each loaded object. *)
    PROPERTY LoadCallback: TCallbackProcedure WRITE fLoadCallback;
  (* This callback is called before save a file.  'num' is num of objects. *)
    PROPERTY PreSaveCallback: TCallbackPrepareProcedure WRITE fPreSaveCallback;
  (* This callback is called for each saved object. *)
    PROPERTY SaveCallback: TCallbackProcedure WRITE fSaveCallback;
  (* Number of objects. *)
    PROPERTY Count: INTEGER READ fCount;
  (* Access to data item. *)
    PROPERTY Item[Ndx: INTEGER]: TDataFileItem READ GetItem;
  END;



IMPLEMENTATION

(* Helper function that gets an Allegro identificator and returns the
 * STRING name. *)
FUNCTION IdToName (Id: LONGINT): STRING;
VAR
  Cnt: INTEGER;
  Tmp: STRING[4];
BEGIN
  Tmp := '    ';
  FOR Cnt := 1 TO 4 DO
  BEGIN
    Tmp[5 - Cnt] := Chr (Id AND $000000FF);
    Id := Id SHR 8;
  END;
  IdToName := Tmp;
END;




(*****************
 * TDataFileItem *
 *****************)

(* Constructor. *)
CONSTRUCTOR TDataFileItem.Create (aObject: AL_DATAFILE_OBJECTptr);
VAR
  Cnt: LONGINT;
BEGIN
  fObjectType := aObject^.ftype;
{ Get properties. }
  fProperties := TStringList.Create;
  Cnt := 0;
  IF aObject^.prop <> NIL THEN
  WHILE aObject^.prop^[Cnt].ftype <> AL_DAT_END DO
  BEGIN
    fProperties.Values[IdToName (aObject^.prop^[Cnt].ftype)] := aObject^.prop^[Cnt].dat;
    INC (Cnt);
  END;
{ TODO: Get data. }
  fSize := aObject^.size;
  GetMem (fData, fSize);
  WriteLn (fSize);
  IF fSize < 900000 THEN
  Move (aObject^.dat^, fData^, fSize);
END;



(* Destructor. *)
DESTRUCTOR TDataFileItem.Destroy;
BEGIN
  IF fProperties <> NIL THEN
    fProperties.Free;
  IF fData <> NIL THEN
    Freemem (fData);
  INHERITED;
END;



(* Returns TRUE if property exists. *)
FUNCTION TDataFileItem.HasProperty (Name: STRING): BOOLEAN;
BEGIN
  RESULT := fProperties.IndexOfName (Name) >= 0;
END;



(* Returns a property. *)
FUNCTION TDataFileItem.GetProperty (Name: STRING): STRING;
BEGIN
  IF NOT HasProperty (Name) THEN
    RAISE Exception.Create ('Not '''+Name+''' property found.');
  RESULT := fProperties.ValueFromIndex[fProperties.IndexOfName(Name)];
END;



(* Creates or modifies a property. *)
PROCEDURE TDataFileItem.SetProperty (Name, Value: STRING);
BEGIN
  IF HasProperty (Name) THEN
    fProperties.Insert (fProperties.IndexOfName (Name), Value)
  ELSE
    fProperties.Add (Name+'='+Value);
END;




(* Returns data type name. *)
FUNCTION TDataFileItem.ObjectTypeName: STRING;
BEGIN
  ObjectTypeName := IdToName (fObjectType);
END;




(* Returns the object name. *)
FUNCTION TDataFileItem.Name: STRING;
BEGIN
  TRY
    Name := GetProperty('NAME');
  EXCEPT
    Name := ObjectTypeName;
  END;
END;



(*************
 * TDataFile *
 *************)

FUNCTION TDataFile.GetItem (Ndx: INTEGER): TDataFileItem;
BEGIN
  RESULT := fData[Ndx];
END;



(* Constructor. *)
CONSTRUCTOR TDataFile.Create;
BEGIN
  SELF.fModified := FALSE;
  fCount := 0;
END;



(* Destructor. *)
DESTRUCTOR TDataFile.Destroy;
BEGIN
  SELF.Clean;
  INHERITED;
END;



(* Cleans the file. *)
PROCEDURE TDataFile.Clean;
VAR
  Cnt: INTEGER;
BEGIN
  IF fCount > 0 THEN
  BEGIN
    FOR Cnt := 0 TO fCount DO
      IF fData[Cnt] <> NIL THEN
      BEGIN
        fData[Cnt].Free;
        fData[Cnt] := NIL;
      END;
    fCount := 0;
  END;
END;



(* Loads the datafile. *)
PROCEDURE TDataFile.LoadFrom (FileName: STRING);
VAR
  DataFile: AL_DATAFILEptr;
  Cnt: INTEGER;
BEGIN
{ TODO: Password support. }
  IF NOT FileExists (FileName) THEN
    RAISE Exception.Create (FileName+' doesn''t exists.');
  DataFile := al_load_datafile (FileName);
  IF DataFile = NIL THEN
    RAISE Exception.Create ('Format error?');
  SELF.Clean;
{ Extracts info. }
  IF fPreLoadCallback <> NIL THEN
  BEGIN
    Cnt := 0;
    WHILE (Cnt < 1024) AND (DataFile^[Cnt].ftype <> AL_DAT_END) DO
      INC (Cnt);
    fPreLoadCallback (Cnt);
  END;
  Cnt := 0;
  WHILE (Cnt < 1024) AND (DataFile^[Cnt].ftype <> AL_DAT_END) DO
  BEGIN
//    Write (DataFile^[Cnt].ftype);
    fData[Cnt] := TDataFileItem.Create (@(DataFile^[Cnt]));
    INC (Cnt); INC (fCount);
    IF fLoadCallback <> NIL THEN
      fLoadCallback ();
  END;
{ Temporal file. }
  al_unload_datafile (DataFile);
  fModified := FALSE;
END;



(* Saves the datafile. *)
PROCEDURE TDataFile.SaveTo (Filename: STRING);
BEGIN
  RAISE Exception.Create ('TDataFile::SaveTo unimplemented!');
END;

END.
