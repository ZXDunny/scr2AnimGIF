unit FastFiles; // FastFiles - ©1999~2001 G-Soft™
                // Updated: 5/07/2001
interface       // http://gfody.com <gfody@home.com>

uses Windows, Math, FastDIB, Classes, SysUtils;

const
  jBufferMode   = 1;
  jReadHeader   = 0;
  jReadEntropy  = 6;
  jWriteImage   = 8;
  jWriteHeader  = 10;
  jWriteEntropy = 12;
  jReadMode: array[0..4]of Byte = (2,14,16,18,20);

  DM_UNDEFINED = 0;
  DM_LEAVE     = 1;
  DM_BGCOLOR   = 2;
  DM_REVERT    = 3;

  BITS = 12;
  HSIZE = 5003;
  maxbits = BITS;
  maxmaxcode: integer = 1 shl BITS;

type
  TGIFOptimisationOpts = Set of (optLZW, optCropping, optColourKey, optFlatBytes);

  TJPGScale = (jsNone,jsHalf,jsQuarter,jsEighth,jsThumbnail);

  TJPGProps = packed record
    UseExProps:     LongBool;
    DIBBytes:       Pointer;
    DIBWidth:       DWord;
    DIBHeight:      Integer;
    DIBPadBytes:    DWord;
    DIBChannels:    DWord;
    DIBColor:       Integer;
    DIBSubsampling: Integer;
    FileName:       PChar;
    JPGBytes:       Pointer;
    JPGSizeBytes:   DWord;
    JPGWidth:       DWord;
    JPGHeight:      DWord;
    JPGChannels:    DWord;
    JPGColor:       Integer;
    JPGSubsampling: Integer;
    JPGThumbWidth:  DWord;
    JPGThumbHeight: DWord;
    NeedsConvert:   LongBool;
    NeedsResample:  LongBool;
    Quality:        DWord;
    UselessCrap1:   array[0..7]of Byte;
    Rect:           TRect;
    IntelDCT:       Boolean;
    UselessCrap2:   array[0..19922]of Byte;
    Smooth:         Boolean;
    UselessCrap3:   array[0..38]of Byte;

  end;

  TFastJPG = class
  private
    fBmp: TFastDIB;
    procedure SetBitmap(Bmp:TFastDIB);
  public
    Props: TJPGProps;
    Scale: TJPGScale;
    ThumbWidth,
    ThumbHeight: DWord;
    constructor Create;
    destructor Destroy; override;
    procedure FlushProps;
    property Bitmap:TFastDIB read fBmp write SetBitmap;
    procedure LoadFile(FileName:string);
    procedure LoadStream(Stream:TStream);
    procedure LoadRes(hInst:Integer;ResID,ResType:string);
    procedure LoadMem(Mem:Pointer;Size:Integer);
    procedure SaveFile(FileName:string);
    procedure SaveStream(Stream:TStream);
    function SaveMem(Mem:Pointer;Size:Integer):Integer;
  end;

  TBitStream = class(TMemoryStream)
  public
     procedure SetDataPointer(Ptr: Pointer; Size: Longint);
  end;

  pal = array[0..255,1..3] of byte;
  PPAL = ^PAL;

procedure LoadBMPFile(Bmp:TFastDIB;FileName:string);
procedure SaveBMPFile(Bmp:TFastDIB;FileName:string);
procedure LoadBMPStream(Bmp:TFastDIB;Stream:TStream);
procedure SaveBMPStream(Bmp:TFastDIB;Stream:TStream);

procedure LoadJPGFile(Bmp:TFastDIB;FileName:string;Smooth:Boolean);
procedure SaveJPGFile(Bmp:TFastDIB;FileName:string;Quality:Integer);
procedure LoadJPGStream(Bmp:TFastDIB;Stream:TStream;Smooth:Boolean);
procedure SaveJPGStream(Bmp:TFastDIB;Stream:TStream;Quality:Integer);
procedure LoadJPGMem(Bmp:TFastDIB;Mem:Pointer;Size:Integer;Smooth:Boolean);
procedure LoadJPGRes(Bmp:TFastDIB;hInst:Integer;ResID,ResType:string;Smooth:Boolean);
function  SaveJPGMem(Bmp:TFastDIB;Mem:Pointer;Size:Integer;Quality:Integer):Integer;
function  FindJPGEOI(Mem:PByte;Size:Integer):Integer;

Procedure SaveGIFFile(Bmp: TFastDIB; Filename: String; Animated: Boolean; Delay: Word; Looped: Boolean);
Procedure AddGIFFrame(Bmp: TFastDIB; Filename: String; Delay: Word; Optimise: Boolean);
Procedure LZWCompress(init_bits: integer; Ins, OutStream: TStream);
Procedure cl_block(OutStream: TStream);
Procedure output(code: integer; OutStream: TStream);
Procedure char_out(c: byte; OutStream: TStream);
Procedure flush_char(OutStream: TStream);

var

  // GIF

  LastGIFFrame: TFastDIB;
  LastGIFDelayPosition,
  GIFFrameNum: Integer;
  LastGIFDelay: Word;

  n_bits: integer;
  maxCode: integer;
  htab: array[0..HSIZE] of integer;
  codetab: array[0..HSIZE] of integer;
  free_ent: integer;
  clear_flg: boolean;
  a_count: integer;
  g_init_bits,
  ClearCode,
  EOFCode: integer;

  cur_accum: integer;
  cur_bits: integer;

  // Intel® Jpeg Library

  HasJPG: Boolean = False;
  JInit:  function(Props:Pointer):Integer; stdcall;
  JFree:  function(Props:Pointer):Integer; stdcall;
  JRead:  function(Props:Pointer;Method:Integer):Integer; stdcall;
  JWrite: function(Props:Pointer;Method:Integer):Integer; stdcall;

implementation

procedure LoadBMPFile(Bmp:TFastDIB;FileName:string);
begin
  Bmp.LoadFromFile(FileName);
end;

procedure SaveBMPFile(Bmp:TFastDIB;FileName:string);
begin
  Bmp.SaveToFile(FileName);
end;

procedure LoadBMPStream(Bmp:TFastDIB;Stream:TStream);
var
  fBits,fSize: Integer;
  Buffer: Pointer;
  bmInfo: TBMInfo;
begin
  fSize:=Stream.Size;
  if fSize>1078 then fSize:=1078;
  GetMem(Buffer,1078);
  Stream.ReadBuffer(Buffer^,fSize);
  fBits:=LoadHeader(Buffer,bmInfo);
  Bmp.SetSizeIndirect(bmInfo);
  Stream.Seek(fBits-fSize,soFromCurrent);
  if(bmInfo.Header.Compression=1)or(bmInfo.Header.Compression=2)then fSize:=(PDWord(Integer(Buffer)+2)^-DWord(fBits))else
  if Stream.Size-fBits > Integer(Bmp.Size) then fSize:=Bmp.Size else fSize:=Stream.Size-fBits;
  if(bmInfo.Header.Compression=0)or(bmInfo.Header.Compression=3)then
    Stream.ReadBuffer(Bmp.Bits^,fSize)else
  begin
    if Stream is TCustomMemoryStream then
    begin
      if bmInfo.Header.Compression=1 then
        DecodeRLE8(Bmp,Ptr(Integer(TCustomMemoryStream(Stream).Memory)+fBits))else
        DecodeRLE4(Bmp,Ptr(Integer(TCustomMemoryStream(Stream).Memory)+fBits));
    end else
    begin
      ReAllocMem(Buffer,fSize);
      Stream.ReadBuffer(Buffer^,fSize);
      if bmInfo.Header.Compression=1 then DecodeRLE8(Bmp,Buffer) else DecodeRLE4(Bmp,Buffer);
    end;
  end;
  FreeMem(Buffer);
end;

procedure SaveBMPStream(Bmp:TFastDIB;Stream:TStream);
var
  cSize: Integer;
  fHead: TBitmapFileHeader;
begin
  if Bmp.Info.Header.ClrUsed<>0 then cSize:=(Bmp.Info.Header.ClrUsed shl 2)
  else if Bmp.Info.Header.Compression=BI_BITFIELDS then cSize:=12
  else if Bmp.Bpp<=8 then cSize:=(1 shl Bmp.Bpp)shl 2
  else cSize:=0;
  fHead.bfType:=$4D42;
  fHead.bfSize:=54+Bmp.Size+DWord(cSize);
  fHead.bfOffBits:=54+cSize;
  Stream.WriteBuffer(fHead,SizeOf(fHead));
  Stream.WriteBuffer(Bmp.Info,40+cSize);
  Stream.WriteBuffer(Bmp.Bits^,Bmp.Size);
end;

procedure LoadJPGFile(Bmp:TFastDIB;FileName:string;Smooth:Boolean);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Smooth:=Smooth;
    LoadFile(FileName);
    Free;
  end;
end;

procedure SaveJPGFile(Bmp:TFastDIB;FileName:string;Quality:Integer);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Quality:=Quality;
    SaveFile(FileName);
    Free;
  end;
end;

procedure LoadJPGStream(Bmp:TFastDIB;Stream:TStream;Smooth:Boolean);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Smooth:=Smooth;
    LoadStream(Stream);
    Free;
  end;
end;

procedure SaveJPGStream(Bmp:TFastDIB;Stream:TStream;Quality:Integer);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Quality:=Quality;
    SaveStream(Stream);
    Free;
  end;
end;

procedure LoadJPGMem(Bmp:TFastDIB;Mem:Pointer;Size:Integer;Smooth:Boolean);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Smooth:=Smooth;
    LoadMem(Mem,Size);
    Free;
  end;
end;

procedure LoadJPGRes(Bmp:TFastDIB;hInst:Integer;ResID,ResType:string;Smooth:Boolean);
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Smooth:=Smooth;
    LoadRes(hInst,ResID,ResType);
    Free;
  end;
end;

function SaveJPGMem(Bmp:TFastDIB;Mem:Pointer;Size,Quality:Integer):Integer;
begin
  if HasJPG then with TFastJPG.Create do
  begin
    Bitmap:=Bmp;
    Props.Quality:=Quality;
    Result:=SaveMem(Mem,Size);
    Free;
  end else Result:=0;
end;

function FindJPGEOI(Mem:PByte;Size:Integer):Integer;
var
  Count: Integer;
begin
  Count:=1;
  while(Size<>0)and(PWord(Mem)^<>$D9FF)do
  begin
    Inc(Mem);
    Inc(Count);
    Dec(Size);
  end;
  Result:=Count;
end;

// TFastJPG 

constructor TFastJPG.Create;
begin
  FillChar(Props,SizeOf(Props),0);
  JInit(@Props);
end;

destructor TFastJPG.Destroy;
begin
  JFree(@Props);
  inherited Destroy;
end;

procedure TFastJPG.FlushProps;
begin
  JFree(@Props);
  FillChar(Props,SizeOf(Props),0);
  JInit(@Props);
end;

procedure TFastJPG.SetBitmap(Bmp:TFastDIB);
begin
  fBmp:=Bmp;
  Props.DIBBytes:=fBmp.Bits;
  Props.DIBWidth:=fBmp.Width;
  Props.DIBHeight:=-fBmp.Height;
  Props.DIBPadBytes:=fBmp.Gap;
  case fBmp.Bpp of
    8:
    begin
      Props.DIBChannels:=1;
      Props.DIBColor:=4;
    end;
    24:
    begin
      Props.DIBChannels:=3;
      Props.DIBColor:=2;
    end;
  end;
end;

procedure TFastJPG.LoadFile(FileName:string);
var
  w,h: Integer;
begin
  Props.FileName:=PChar(FileName);
  JRead(@Props,jReadHeader);

  w:=Props.JPGWidth shr Byte(Scale);
  h:=Props.JPGHeight shr Byte(Scale);
  if Scale=jsThumbnail then
  begin
    w:=ThumbWidth;
    h:=ThumbHeight;
  end;

  if(Props.JPGChannels=1)then
  begin
    Bitmap.SetSize(w,h,8);
    Bitmap.FillColors(0,255,[tfBlack,tfWhite]);
    Props.DIBChannels:=1;
    Props.DIBColor:=4;
  end else
  begin
    Bitmap.SetSize(w,h,24);
    Props.DIBChannels:=3;
    Props.DIBColor:=2;
  end;

  Props.DIBBytes:=Bitmap.Bits;
  Props.DIBWidth:=Bitmap.Width;
  Props.DIBHeight:=-Bitmap.Height;
  Props.DIBPadBytes:=Bitmap.Gap;

  JRead(@Props,jReadMode[Byte(Scale)]);

end;

procedure TFastJPG.LoadStream(Stream:TStream);
var
  Buffer: Pointer;
  BSize,JSize,Pos: Integer;
begin
  Pos:=Stream.Position;
  BSize:=Stream.Size-Pos;
  if Stream is TCustomMemoryStream then
  begin
    JSize:=FindJPGEOI(Ptr(Integer(TCustomMemoryStream(Stream).Memory)+Pos),BSize);
    LoadMem(Ptr(Integer(TCustomMemoryStream(Stream).Memory)+Pos),BSize);
    Stream.Position:=Pos+JSize;
  end else
  begin
    GetMem(Buffer,BSize);
    Stream.Read(Buffer^,BSize);
    JSize:=FindJPGEOI(Buffer,BSize);
    LoadMem(Buffer,BSize);
    Stream.Position:=Pos+JSize;
    FreeMem(Buffer);
  end;
end;

procedure TFastJPG.LoadRes(hInst:Integer;ResID,ResType:string);
var
  pMem: Pointer;
  hRes,Size: Integer;
begin
  hRes:=FindResource(hInst,PChar(ResID),PChar(ResType));
  Size:=SizeofResource(hInst,hRes);
  pMem:=LockResource(LoadResource(hInst,hRes));
  if pMem<>nil then LoadMem(pMem,Size);
end;

procedure TFastJPG.LoadMem(Mem:Pointer;Size:Integer);
var
  w,h: Integer;
begin
  Props.JPGBytes:=Mem;
  Props.JPGSizeBytes:=Size;
  JRead(@Props,jReadHeader or jBufferMode);

  w:=Props.JPGWidth shr Byte(Scale);
  h:=Props.JPGHeight shr Byte(Scale);
  if Scale=jsThumbnail then
  begin
    w:=Props.JPGThumbWidth;
    h:=Props.JPGThumbHeight;
  end;

  if(Props.JPGChannels=1)then
  begin
    Bitmap.SetSize(w,h,8);
    Bitmap.FillColors(0,255,[tfBlack,tfWhite]);
    Props.DIBChannels:=1;
    Props.DIBColor:=4;
  end else
  begin
    Bitmap.SetSize(w,h,24);
    Props.DIBChannels:=3;
    Props.DIBColor:=2;
  end;

  Props.DIBBytes:=Bitmap.Bits;
  Props.DIBWidth:=Bitmap.Width;
  Props.DIBHeight:=-Bitmap.Height;
  Props.DIBPadBytes:=Bitmap.Gap;
  JRead(@Props,jReadMode[Byte(Scale)]or jBufferMode);
end;

procedure TFastJPG.SaveFile(FileName:string);
begin
  Props.DIBBytes:=Bitmap.Bits;
  Props.DIBWidth:=Bitmap.Width;
  Props.DIBHeight:=-Bitmap.Height;
  Props.DIBPadBytes:=Bitmap.Gap;
  if(Bitmap.Bpp=8)then
  begin
    Props.DIBChannels:=1;
    Props.DIBColor:=4;
  end;

  Props.FileName:=PChar(FileName);
  Props.JPGWidth:=Bitmap.Width;
  Props.JPGHeight:=Bitmap.AbsHeight;

  JWrite(@Props,jWriteImage)
end;

procedure TFastJPG.SaveStream(Stream:TStream);
var
  Buffer: Pointer;
  Size: Integer;
begin
  GetMem(Buffer,Bitmap.Size);
  Size:=SaveMem(Buffer,Bitmap.Size);
  Stream.WriteBuffer(Buffer^,Size);
  FreeMem(Buffer);
end;

function TFastJPG.SaveMem(Mem:Pointer;Size:Integer):Integer;
begin
  Props.DIBBytes:=Bitmap.Bits;
  Props.DIBWidth:=Bitmap.Width;
  Props.DIBHeight:=-Bitmap.Height;
  Props.DIBPadBytes:=Bitmap.Gap;
  if(Bitmap.Bpp=8)then
  begin
    Props.DIBChannels:=1;
    Props.DIBColor:=4;
  end;

  Props.JPGBytes:=Mem;
  Props.JPGSizeBytes:=Size;
  Props.JPGWidth:=Bitmap.Width;
  Props.JPGHeight:=Bitmap.AbsHeight;

  JWrite(@Props,jWriteImage or jBufferMode);
  Result:=Props.JPGSizeBytes;
end;

procedure SetIJLCPUKey;
var
  Key: HKEY;
  CPUKey,Dummy: Integer;
begin
  CPUKey:=0;

  // determine Pentium, Pentium Pro, Pentium II
  if CPUInfo.VendorID='GenuineIntel' then
    if CPUInfo.Family=5 then CPUKey:=1 else if CPUInfo.Family=6 then
      if CPUInfo.Model > 1 then CPUKey:=4 else CPUKey:=2;

  // determine MMX, Pentium III, Pentium 4
  if(cfMMX in CPUInfo.Features)and(CPUKey < 3)then CPUKey:=3;
  if cfSSE in CPUInfo.Features then CPUKey:=5;
  if cfSSE2 in CPUInfo.Features then CPUKey:=6;

  RegCreateKeyEx(
    HKEY_LOCAL_MACHINE,'SOFTWARE\Intel Corporation\PLSuite\IJLib',0,nil,
    REG_OPTION_NON_VOLATILE,KEY_WRITE,nil,Key,@Dummy);

  RegSetValueEx(Key,'USECPU',0,REG_DWORD,@CPUKey,4);
  RegCloseKey(Key);
end;

// *** GIF Output ***

procedure TBitStream.SetDataPointer(Ptr: Pointer; Size: Longint);
begin
   SetPointer(Ptr,Size);
end;

Procedure SaveGIFFile(Bmp: TFastDIB; Filename: String; Animated: Boolean; Delay: Word; Looped: Boolean);
Var
  FileStream: TFileStream;
  iWidth, iHeight: Word;
  Idx: Integer;
  iFlags, iBackgroundIndex, iPixelAspect: Byte;
Const
  Header: AnsiString = 'GIF89a';
  LoopBlock: AnsiString = #33#255#11+'NETSCAPE2.0'+#3#1#0#0#0;
  Terminator: Byte = $0;
Begin

  // Saves a FastDIB as a GIF image. BPP must be 8, size doesn't matter.
  // 8Bpp only, because every pixel in a GIF image must occupy one byte. Pah!
  // Opens a stream, TFastGIFStream, which remains open for further anim frames to be appended.
  // If not animated, just saves the file.

  If Bmp.Bpp <= 8 Then Begin

     FileStream := TFileStream.Create(Filename, fmCreate or fmShareDenyNone);

     // Write the GIF header

     FileStream.Write(Header[1], 6);

     // And the "viewport" dimensions

     iWidth := Bmp.Width;
     iHeight := Bmp.AbsHeight;
     iBackgroundIndex := 0;              // Assume colour 0 as background.
     iPixelAspect := 0;                  // Aspect Ratio is undefined - duh.
     iFlags :=   128 +                   // Global palette follows
                 ((Bmp.Bpp -1) Shl 4) +  // 8 Bits per channel - seems to be bpp in paintshop?
                 0 +                     // No sort
                 Bmp.Bpp -1;             // Bits per pixel.

     FileStream.Write(iWidth, 2);
     FileStream.Write(iHeight, 2);
     FileStream.Write(iFlags, 1);
     FileStream.Write(iBackgroundIndex, 1);
     FileStream.Write(iPixelAspect, 1);

     // Write a global palette block

     For Idx := 0 To (1 Shl Bmp.Bpp) -1 Do Begin
        FileStream.Write(Bmp.Colors[Idx].r, 1);
        FileStream.Write(Bmp.Colors[Idx].g, 1);
        FileStream.Write(Bmp.Colors[Idx].b, 1);
     End;

     // Save a copy of this first frame for use in the optimisation
     // Procedures later, if it's an animated GIF.

     If Animated Then Begin
        LastGIFFrame := TFastDIB.Create;
        LastGIFFrame.SetSize(Bmp.Width, Bmp.Height, 8);
        LastGIFFrame.Colors := Bmp.Colors;
        LastGIFFrame.UpdateColors;
        Bmp.Draw(LastGIFFrame.hDc, 0, 0);
        GIFFrameNum := 0;
        If Looped Then
           FileStream.Write(LoopBlock[1], 19);
     End;


     // All done. Images are added using a subsequent AddGIFFrame() procedure call.
     // Which, by a strange coincidence, is how we add the first frame :)

     FileStream.Free;

     AddGIFFrame(Bmp, Filename, Delay, False);

     // If the file is not to be animated, then finish it now.

     If Not Animated Then
        AddGIFFrame(Nil, Filename, 0, False);

  End;

End;

Procedure AddGIFFrame(Bmp: TFastDIB; Filename: String; Delay: Word; Optimise: Boolean);
Var
  iWidth, iHeight, iLeft, iTop, AdjustY, CmpSize, LastColour, Idx1, Idx2, X, Y, MaxColour, MinX, MinY, MaxX, MaxY: Integer;
  TempBits, Opt_Array: Array of Byte;
  ColoursUsed: Array[0..255] of Boolean;
  FileStream: TFileStream;
  Clr, TransparentIndex, GraphicDisposeMethod, iFlags: Byte;
  TransparentOK: Boolean;
  NewDelay: Word;
  CmpBits: Pointer;
  BitsStream: TBitStream;
Const
  ImageSeparator: Byte = $2C;
  ExtensionIntro: Byte = $21;
  GraphicControlId: Byte = $F9;
  GraphicBlockSize: Byte = $4;
  GraphicBlockTerminator: Byte = $0;
  Terminator: Word = $3B;
Begin

  // Adds a frame to a GIF File. A delay of 0 indicates that this is the first frame
  // and therefore does not require a Graphic Control block.
  // A Bmp of "nil" finishes the GIF File with a terminator block. Neat :)

  FileStream := TFilestream.Create(Filename, fmOpenReadWrite or fmShareDenyNone);
  FileStream.Seek(0, soFromEnd);

  If Bmp <> nil Then Begin

     // Create a temporary 8bpp storage - it's faster than working on a DIB that's
     // possibly only 16 colours or less.

     SetLength(TempBits, Bmp.Width * Bmp.AbsHeight);

     If Optimise Then Begin

        // Now examine the image to determine:
        // 1. Which pixels have changed, and the smallest rectangle that encompasses them
        // 2. Which colours have not been used - we can use one of them as the transparent colour

        MaxX := 0;
        MaxY := 0;
        MinX := Bmp.Width;
        MinY := Bmp.AbsHeight;

        For Idx1 := 0 To 255 Do
           ColoursUsed[Idx1] := False;

        For Y := 0 To Bmp.AbsHeight -1 Do Begin

           AdjustY := (Bmp.AbsHeight -1) - Y;

           For X := 0 To Bmp.Width -1 Do Begin

              Clr := Bmp.PixelsB[AdjustY, X];
              ColoursUsed[Clr] := True;
              TempBits[(Y * Bmp.Width) + X] := Clr;

              If LastGIFFrame.Pixels8[AdjustY, X] <> Clr Then Begin

                 If X > MaxX Then MaxX := X;
                 If X < MinX Then MinX := X;
                 If Y > MaxY Then MaxY := Y;
                 If Y < MinY Then MinY := Y;

              End;

           End;

        End;

        // No pixels changed? Change last delay if so - no point in storing an image.

        If (MaxX = 0) and (MinX = Bmp.Width) and (MaxY = 0) and (MinY = Bmp.AbsHeight) Then Begin

           NewDelay := LastGIFDelay + Delay;
           LastGIFDelay := NewDelay;
           FileStream.Seek(LastGIFDelayPosition, soFromBeginning);
           FileStream.Write(NewDelay, 2);
           FileStream.Seek(0, soFromEnd);
           FileStream.Free;
           Exit;

        End;

        // Now we have our rectangle and colour information.
        // Get the index of the first available unused colour for our transparency keying.

        TransparentIndex := 0;
        While ColoursUsed[TransparentIndex] and (TransparentIndex <= (1 Shl Bmp.Bpp)) Do
           Inc(TransparentIndex);

        TransparentOK := TransparentIndex < (1 Shl Bmp.bpp);
        TransparentIndex := Min(TransparentIndex, $FF);

        // Set up the second array that will hold our optimised image.

        iWidth := (MaxX - MinX) +1;
        iHeight := (MaxY - MinY) +1;

        SetLength(Opt_Array, iWidth * iHeight);

        // And start copying the pixels across from the temporary array.
        // Whilst doing this, Set the Transparency keying, LZW optimisation and the maximum bitdepth required
        // to display this image.

        Idx2 := 0;
        MaxColour := 0;

        For Y := MinY To MaxY Do Begin

           Idx1 := (Y * Bmp.Width) + MinX;
           AdjustY := Bmp.AbsHeight - 1 - Y;

           For X := MinX To MaxX Do Begin

              If TransparentOK Then Begin

                 // We successfully found a transparent colour that can be used.

                 If TempBits[Idx1] = LastGIFFrame.Pixels8[AdjustY, X] Then Begin

                    // Pixel was unchanged from the last frame - a candidate for transparency.

                    If Idx2 mod iWidth > 0 Then Begin

                       If TempBits[Idx1] <> Opt_Array[Idx2 -1] Then
                          Opt_Array[Idx2] := TransparentIndex
                       Else
                          Opt_Array[Idx2] := TempBits[Idx1];

                    End Else

                       Opt_Array[Idx2] := TransparentIndex;

                 End Else

                    Opt_Array[Idx2] := TempBits[Idx1];

              End Else

                 // There was no transparent colour that can be used, without extending
                 // the bitdepth. In this case, we have to store the full frame.

                 Opt_Array[Idx2] := TempBits[Idx1];

              If Opt_Array[Idx2] > MaxColour Then
                 MaxColour := Opt_Array[Idx2];

              Inc(Idx1);
              Inc(Idx2);

           End;

           // Further LZW optimisation - run along the Optimised image backwards,
           // Ensuring again that long runs of pixels are preserved.

           LastColour := -1;

           Dec(Idx2);

           For X := MaxX DownTo MinX Do Begin

              If LastColour > -1 Then
                 If Opt_Array[Idx2] = TransparentIndex Then
                    If LastGIFFrame.Pixels8[AdjustY, X] = LastColour Then
                       Opt_Array[Idx2] := LastColour;

              LastColour := Opt_Array[Idx2];
              Dec(Idx2);

           End;

           Inc(Idx2, iWidth +1);

        End;

        // This won't always gain you some bytes, but it shouldn't lose any.
        // Note - LZW Encryption won't happen with 1bpp images, they must be 2bpp.

        Case MaxColour of
           0..1:     MaxColour := 2;
           2..3:     MaxColour := 2;
           4..7:     MaxColour := 3;
           8..15:    MaxColour := 4;
           16..31:   MaxColour := 5;
           32..63:   MaxColour := 6;
           64..127:  MaxColour := 7;
           128..255: MaxColour := 8;
        Else
           MaxColour := 8;
        End;

        // Update the last frame with the current image.

        Bmp.Draw(LastGIFFrame.hdc, 0, 0);

        // And now set up some information for the headers that we're going to write.

        CmpBits := @Opt_Array[0];
        CmpSize := Length(Opt_Array);
        iLeft := MinX;
        iTop := MinY;

     End Else Begin

        // No optimisation - either the user doesn't want any, or it's the first frame in the bitmap.
        // Create an 8bpp image of the bitmap.

        For Y := 0 To Bmp.AbsHeight -1 Do
           For X := 0 To Bmp.Width -1 Do
              TempBits[((Bmp.AbsHeight - 1 - Y) * Bmp.Width) + X] := Bmp.PixelsB[Y, X];

        // And set up the vars for the image writer.

        CmpBits := @TempBits[0];
        CmpSize := Length(TempBits);
        iLeft := 0;
        iTop := 0;
        iWidth := Bmp.Width;
        iHeight := Bmp.AbsHeight;
        TransparentIndex := $FF;
        TransparentOK := False;
        MaxColour := Bmp.Bpp;

     End;

     // And write the image!

     If Delay > 0 Then Begin

        // Write a Graphic Control block if the Delay > 0

        FileStream.Write(ExtensionIntro, 1);
        FileStream.Write(GraphicControlID, 1);
        FileStream.Write(GraphicBlockSize, 1);

        GraphicDisposeMethod := 4; // Do not dispose
        If TransparentOK Then
           GraphicDisposeMethod := GraphicDisposeMethod or 1;
        FileStream.Write(GraphicDisposeMethod, 1);

        LastGIFDelayPosition := FileStream.Position; // Saved in case the next frame is identical to this one.
        FileStream.Write(Delay, 2);
        LastGIFDelay := Delay;

        FileStream.Write(TransparentIndex, 1);
        FileStream.Write(GraphicBlockTerminator, 1);

     End;

     // Start the Image descriptor.

     iFlags := 0; // No local colour table, no sorting, no nothing.

     // Write the image header

     FileStream.Write(ImageSeparator, 1);
     FileStream.Write(iLeft, 2);
     FileStream.Write(iTop, 2);
     FileStream.Write(iWidth, 2);
     FileStream.Write(iHeight, 2);
     FileStream.Write(iFlags, 1);

     // And now - write the Image Data

     BitsStream := TBitStream.Create;
     BitsStream.SetDataPointer(CmpBits, CmpSize);

     LZWCompress(MaxColour +1, BitsStream, FileStream);

     BitsStream.Free;

     // Finish the block with a zero byte
     FileStream.Write(GraphicBlockTerminator, 1);

  End Else Begin

     FileStream.Write(Terminator, 1);
     LastGIFFrame.Free;

  End;

  Inc(GIFFrameNum);
  FileStream.Free;

End;

function MAX_CODE(n_bits: integer): integer;
begin
   max_code:=(1 shl n_bits) -1;
end;

Procedure cl_hash(hsize: integer);
var
   i: integer;
Begin
   for i := 0 to hsize-1 do
      htab[i] := -1;
End;

Procedure LZWCompress(init_bits: integer; Ins, OutStream: TStream );
const
  EOF=-1;
  read_bufer_size=2048;
var
  aa, fcode, i, c, ent, disp, hsize_reg, hshift, numRead: integer;
  Rbuf: array[1..read_bufer_size] of byte;
  rdpos: ^byte;
label
  outer_loop;

  Function NextPixel: integer;
  label
     ex1;
  Begin
     if numRead = 0 then begin
        NumRead := Ins.size-Ins.position;
        if numRead > read_bufer_size then
           NumRead := read_bufer_size;
        if numRead = 0 then begin

        ex1:
           c := EOF;
           NextPixel := c;
           Exit;
        end;
        Ins.Read(Rbuf, numread);
        RdPos := @rbuf;
     end;

     c := rdPos^;
     inc(rdPos);
     dec(NumRead);
     NextPixel := c;
  End;

Begin
  aa := init_bits-1;
  OutStream.Write(aa, 1);

    numRead := 0;
  cur_accum := 0;
   cur_bits := 0;
    a_count := 0;

  g_init_bits := init_bits;

  clear_flg := false;
     n_bits := g_init_bits;
    maxcode := MAX_CODE(n_bits);

  ClearCode := 1 shl (init_bits -1);
    EOFCode := ClearCode +1;
   free_ent := ClearCode +2;

  NextPixel;
  ent := c;

  hshift := 0;
  fcode := hsize;
  while fcode < 65536 do begin
   fcode := fcode * 2;
   hshift := hshift + 1;
  end;

  hshift := 8 - hshift;
  hsize_reg := hsize;
  Cl_hash(hsize_reg);
  Output(ClearCode, OutStream);

outer_loop:

  while nextPixel <> EOF do begin
     fcode := (c  shl  maxbits) + ent;
     i := (c shl hshift) xor ent;

     if (htab[i] = fcode) then begin
        ent := codetab[i];
        continue;
     end else
        if (htab[i] >= 0) then begin
           disp := hsize_reg - i;
           if (i = 0) then
              disp := 1;
           repeat
              i := i - disp;
              if i < 0 then
                 i := i + hsize_reg;
              if (htab[i] = fcode) then begin
                 ent := codetab[i];
                 goto outer_loop;
              end;
           until (htab[i] < 0);
        end;

     Output(ent, OutStream);
     ent := c;
     if (free_ent < maxmaxcode) then begin
        codetab[i] := free_ent ;
        inc(free_ent);
        htab[i] := fcode;
     end else
        Cl_block(OutStream);
  end;
  Output(ent, OutStream);
  Output(EOFCode, OutStream);
End;

Procedure cl_block(OutStream:TStream);
begin
  cl_hash(hsize);
  free_ent := ClearCode + 2;
  clear_flg := true;
  Output(ClearCode, OutStream);
end;

Procedure Output(code: integer; OutStream: TStream);
Begin
  cur_accum := cur_accum and (1 shl cur_bits - 1);

  if (cur_bits > 0) then
     cur_accum:= cur_accum or (code  shl  cur_bits)
  else
     cur_accum := code;

  cur_bits := cur_bits + n_bits;

  while (cur_bits >= 8) do begin
     char_out(cur_accum and $ff, OutStream);
     cur_accum := cur_accum  shr 8;
     dec(cur_bits, 8);
  end;

  if (free_ent > maxcode) or clear_flg then
     if clear_flg then begin
        n_bits := g_init_bits;
        maxcode := MAX_CODE(n_bits);
        clear_flg := false;
     end else begin
        inc(n_bits);
        if (n_bits = maxbits) then
           maxcode := maxmaxcode
        else
           maxcode := MAX_CODE(n_bits);
        end;

     if (code = EOFCode) then begin
        while (cur_bits > 0) do begin
           char_out(cur_accum and $ff, OutStream);
           cur_accum:=cur_accum  shr 8;
           dec(cur_bits, 8);
        end;
        flush_char(OutStream);
     end;
  End;

var
  accum:array[-1..255] of byte;

  Procedure char_out(c: byte; OutStream: TStream);
  begin
     accum[a_count] := c;
     inc(a_count);
     if (a_count > 254) then
        flush_char(OutStream);
  end;

  Procedure flush_char(OutStream: TStream);
  Begin
     if (a_count > 0) then begin
        accum[-1] := a_count;
        OutStream.Write(accum, a_count+1);
        a_count := 0;
     end;
  End;


var
  hIJL: HINST;

initialization

  hIJL:=LoadLibrary('ijl15.dll');
  if hIJL<>0 then
  begin
    SetIJLCPUKey;
    HasJPG:=True;

    @JInit:=GetProcAddress(hIJL,'ijlInit');
    @JFree:=GetProcAddress(hIJL,'ijlFree');
    @JRead:=GetProcAddress(hIJL,'ijlRead');
    @JWrite:=GetProcAddress(hIJL,'ijlWrite');
  end;

finalization

  FreeLibrary(hIJL);

end.
