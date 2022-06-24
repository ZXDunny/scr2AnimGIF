unit FastSize;         // FastSize updated: 8/19/99
                       // by: gordy <gfody@jps.net> www.jps.net/gfody
interface              //   Functions for resampling one TFastDIB to
                       //   another TFastDIB of different size. These
uses Windows, FastDIB, //   functions assume that Src.Bpp = Dst.Bpp!
     FastFX, FastFiles;

type
  TRGBArray = ARRAY[0..32767] OF TRGBTriple;
  pRGBArray = ^TRGBArray;

procedure Quick2x(Src,Dst:TFastDIB);
procedure   Quick2x8(Src,Dst:TFastDIB);
procedure   Quick2x16(Src,Dst:TFastDIB);
procedure   Quick2x24(Src,Dst:TFastDIB);
procedure   Quick2x32(Src,Dst:TFastDIB);

procedure FastResize(Src,Dst:TFastDIB);
procedure   FastResize8(Src,Dst:TFastDIB);
procedure   FastResize16(Src,Dst:TFastDIB);
procedure   FastResize24(Src,Dst:TFastDIB);
procedure   FastResize32(Src,Dst:TFastDIB);

procedure Bilinear(Src,Dst:TFastDIB);
procedure   Bilinear8(Src,Dst:TFastDIB);
procedure   Bilinear16(Src,Dst:TFastDIB);
procedure   Bilinear24(Src,Dst:TFastDIB);
procedure   Bilinear32(Src,Dst:TFastDIB);

Procedure DownSize(Src, Dst: TFastDIB);
procedure SmoothResize(abmp, bBmp: TFastDIB);

implementation

procedure Quick2x8(Src,Dst:TFastDIB);
var
  x,y:   Integer;
  ps,pd: PByte;
begin
  ps:=Pointer(Src.Bits);
  pd:=Pointer(Dst.Bits);
  for y:=0 to Src.AbsHeight-1 do
  begin
    for x:=0 to Src.Width-1 do
    begin
      pd^:=ps^; Inc(pd);
      pd^:=ps^; Inc(pd);
      Inc(ps);
    end;
    Inc(pd,Dst.Gap);
    Move(Ptr(Integer(pd)-Dst.BWidth)^,pd^,Dst.BWidth);
    Inc(pd,Dst.BWidth+Dst.Gap);
    Inc(ps,Src.Gap);
  end;
end;

procedure Quick2x16(Src,Dst:TFastDIB);
var
  x,y:   Integer;
  ps,pd: PWord;
begin
  ps:=Pointer(Src.Bits);
  pd:=Pointer(Dst.Bits);
  for y:=0 to Src.AbsHeight-1 do
  begin
    for x:=0 to Src.Width-1 do
    begin
      pd^:=ps^; Inc(pd);
      pd^:=ps^; Inc(pd);
      Inc(ps);
    end;
    pd:=Ptr(Integer(pd)+Dst.Gap);
    Move(Ptr(Integer(pd)-Dst.BWidth)^,pd^,Dst.BWidth);
    pd:=Ptr(Integer(pd)+Dst.BWidth+Dst.Gap);
    ps:=Ptr(Integer(ps)+Src.Gap);
  end;
end;

procedure Quick2x24(Src,Dst:TFastDIB);
var
  x,y:   Integer;
  ps,pd: PFColor;
begin
  ps:=Pointer(Src.Bits);
  pd:=Pointer(Dst.Bits);
  for y:=0 to Src.AbsHeight-1 do
  begin
    for x:=0 to Src.Width-1 do
    begin
      pd^:=ps^; Inc(pd);
      pd^:=ps^; Inc(pd);
      Inc(ps);
    end;
    pd:=Ptr(Integer(pd)+Dst.Gap);
    Move(Ptr(Integer(pd)-Dst.BWidth)^,pd^,Dst.BWidth);
    pd:=Ptr(Integer(pd)+Dst.BWidth+Dst.Gap);
    ps:=Ptr(Integer(ps)+Src.Gap);
  end;
end;

procedure Quick2x32(Src,Dst:TFastDIB);
var
  x,y:   Integer;
  ps,pd: PFColorA;
begin
  ps:=Pointer(Src.Bits);
  pd:=Pointer(Dst.Bits);
  for y:=0 to Src.AbsHeight-1 do
  begin
    for x:=0 to Src.Width-1 do
    begin
      pd^:=ps^; Inc(pd);
      pd^:=ps^; Inc(pd);
      Inc(ps);
    end;
    pd:=Ptr(Integer(pd)+Dst.Gap);
    Move(Ptr(Integer(pd)-Dst.BWidth)^,pd^,Dst.BWidth);
    pd:=Ptr(Integer(pd)+Dst.BWidth+Dst.Gap);
    ps:=Ptr(Integer(ps)+Src.Gap);
  end;
end;

procedure Quick2x(Src,Dst:TFastDIB);
begin
  case Dst.Bpp of
    8:  Quick2x8(Src,Dst);
    16: Quick2x16(Src,Dst);
    24: Quick2x24(Src,Dst);
    32: Quick2x32(Src,Dst);
  end;
end;

procedure FastResize8(Src,Dst:TFastDIB);
var
  x,y,xp,yp,sx,sy: Integer;
  Line: PLine8;
  pc: PByte;
begin
  sx:=(Src.Width shl 16)div Dst.Width;
  sy:=(Src.AbsHeight shl 16)div Dst.AbsHeight;
  yp:=0; pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    Line:=Src.Scanlines[yp shr 16]; xp:=0;
    for x:=0 to Dst.Width-1 do
    begin
      pc^:=Line[xp shr 16];
      Inc(pc); Inc(xp,sx);
    end;
    Inc(pc,Dst.Gap);
    Inc(yp,sy);
  end;
end;

procedure FastResize16(Src,Dst:TFastDIB);
var
  x,y,xp,yp,sx,sy: Integer;
  Line: PLine16;
  pc: PWord;
begin
  sx:=(Src.Width shl 16)div Dst.Width;
  sy:=(Src.AbsHeight shl 16)div Dst.AbsHeight;
  yp:=0; pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    Line:=Src.Scanlines[yp shr 16]; xp:=0;
    for x:=0 to Dst.Width-1 do
    begin
      pc^:=Line[xp shr 16];
      Inc(pc); Inc(xp,sx);
    end;
    pc:=Ptr(Integer(pc)+Dst.Gap);
    Inc(yp,sy);
  end;
end;

procedure FastResize24(Src,Dst:TFastDIB);
var
  x,y,xp,yp,sx,sy: Integer;
  Line: PLine24;
  pc: PFColor;
begin
  sx:=(Src.Width shl 16)div Dst.Width;
  sy:=(Src.AbsHeight shl 16)div Dst.AbsHeight;
  yp:=0; pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    Line:=Src.Scanlines[yp shr 16]; xp:=0;
    for x:=0 to Dst.Width-1 do
    begin
      pc^:=Line[xp shr 16];
      Inc(pc); Inc(xp,sx);
    end;
    pc:=Ptr(Integer(pc)+Dst.Gap);
    Inc(yp,sy);
  end;
end;

procedure FastResize32(Src,Dst:TFastDIB);
var
  x,y,xp,yp,sx,sy: Integer;
  Line: PLine32;
  pc: PFColorA;
begin
  sx:=(Src.Width shl 16)div Dst.Width;
  sy:=(Src.AbsHeight shl 16)div Dst.AbsHeight;
  yp:=0; pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    Line:=Src.Scanlines[yp shr 16]; xp:=0;
    for x:=0 to Dst.Width-1 do
    begin
      pc^:=Line[xp shr 16];
      Inc(pc); Inc(xp,sx);
    end;
    pc:=Ptr(Integer(pc)+Dst.Gap);
    Inc(yp,sy);
  end;
end;

procedure FastResize(Src,Dst:TFastDIB);
begin
  case Src.Bpp of
    8:  FastResize8(Src,Dst);
    16: FastResize16(Src,Dst);
    24: FastResize24(Src,Dst);
    32: FastResize32(Src,Dst);
  end;
end;

procedure Bilinear8(Src,Dst:TFastDIB);
var
  x,y,xp,yp,ypp,xpp,t,
  z,z2,iz2,w1,w2,w3,w4: Integer;
  y1,y2: PLine8;
  pc: PByte;
begin
  yp:=0;
  xpp:=((Src.Width-1)shl 16)div Dst.Width;
  ypp:=((Src.AbsHeight-1)shl 16)div Dst.AbsHeight;
  pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    xp:=yp shr 16;
    y1:=Src.Scanlines[xp];
    if xp<Src.AbsHeight-1 then Inc(xp);
    y2:=Src.Scanlines[xp];
    xp:=0;
    z2:=(yp and $FFFF)+1;
    iz2:=((not yp)and $FFFF)+1;
    for x:=0 to Dst.Width-1 do
    begin
      t:=xp shr 16;
      z:=xp and $FFFF;
      w2:=(iz2*z)shr 16;
      w1:=iz2-w2;
      w4:=(z2*z)shr 16;
      w3:=z2-w4;
      pc^:=(y1[t]*w1+y1[t+1]*w2+y2[t]*w3+y2[t+1]*w4)shr 16;
      Inc(xp,xpp);
      Inc(pc);
    end;
    Inc(yp,ypp);
    Inc(pc,Dst.Gap);
  end;
end;

procedure Bilinear16(Src,Dst:TFastDIB);
var
  x,y,xp,yp,ypp,xpp,t,
  z,z2,iz2,w1,w2,w3,w4: Integer;
  y1,y2: PLine16;
  pc: PWord;
  ri,gi,bi: array[Word]of Byte;
  rw,gw,bw: array[Byte]of Word;
begin
  for x:=0 to 65535 do
  begin
    bi[x]:=x shl Src.BShr;
    gi[x]:=x shr Src.GShl shl Src.GShr;
    ri[x]:=x shr Src.RShl shl Src.RShr;
  end;
  for x:=0 to 255 do
  begin
    bw[x]:=x shr Dst.BShr;
    gw[x]:=x shr Dst.GShr shl Dst.GShl;
    rw[x]:=x shr Dst.RShr shl Dst.RShl;
  end;
  yp:=0;
  xpp:=((Src.Width-1)shl 16)div Dst.Width;
  ypp:=((Src.AbsHeight-1)shl 16)div Dst.AbsHeight;
  pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    xp:=yp shr 16;
    y1:=Src.Scanlines[xp];
    if xp<Src.AbsHeight-1 then Inc(xp);
    y2:=Src.Scanlines[xp];
    xp:=0;
    z2:=(yp and $FFFF)+1;
    iz2:=((not yp)and $FFFF)+1;
    for x:=0 to Dst.Width-1 do
    begin
      t:=xp shr 16;
      z:=xp and $FFFF;
      w2:=(iz2*z)shr 16;
      w1:=iz2-w2;
      w4:=(z2*z)shr 16;
      w3:=z2-w4;
      pc^:=
        bw[(bi[y1[t]]*w1+bi[y1[t+1]]*w2+bi[y2[t]]*w3+bi[y2[t+1]]*w4)shr 16]or
        gw[(gi[y1[t]]*w1+gi[y1[t+1]]*w2+gi[y2[t]]*w3+gi[y2[t+1]]*w4)shr 16]or
        rw[(ri[y1[t]]*w1+ri[y1[t+1]]*w2+ri[y2[t]]*w3+ri[y2[t+1]]*w4)shr 16];
      Inc(xp,xpp);
      Inc(pc);
    end;
    Inc(yp,ypp);
    pc:=Ptr(Integer(pc)+Dst.Gap);
  end;
end;

procedure Bilinear24(Src,Dst:TFastDIB);
var
  x,y,xp,yp,ypp,xpp,t,
  z,z2,iz2,w1,w2,w3,w4: Integer;
  y1,y2: PLine24;
  pc: PFColor;
begin
  yp:=0;
  xpp:=((Src.Width-1)shl 16)div Dst.Width;
  ypp:=((Src.AbsHeight-1)shl 16)div Dst.AbsHeight;
  pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    xp:=yp shr 16;
    y1:=Src.Scanlines[xp];
    if xp<Src.AbsHeight-1 then Inc(xp);
    y2:=Src.Scanlines[xp];
    xp:=0;
    z2:=(yp and $FFFF)+1;
    iz2:=((not yp)and $FFFF)+1;
    for x:=0 to Dst.Width-1 do
    begin
      t:=xp shr 16;
      z:=xp and $FFFF;
      w2:=(iz2*z)shr 16;
      w1:=iz2-w2;
      w4:=(z2*z)shr 16;
      w3:=z2-w4;
      pc.b:=(y1[t].b*w1+y1[t+1].b*w2+y2[t].b*w3+y2[t+1].b*w4)shr 16;
      pc.g:=(y1[t].g*w1+y1[t+1].g*w2+y2[t].g*w3+y2[t+1].g*w4)shr 16;
      pc.r:=(y1[t].r*w1+y1[t+1].r*w2+y2[t].r*w3+y2[t+1].r*w4)shr 16;
      Inc(xp,xpp);
      Inc(pc);
    end;
    Inc(yp,ypp);
    pc:=Ptr(Integer(pc)+Dst.Gap);
  end;
end;

procedure Bilinear32(Src,Dst:TFastDIB);
var
  x,y,xp,yp,ypp,xpp,t,
  z,z2,iz2,w1,w2,w3,w4: Integer;
  y1,y2: PLine32;
  pc: PFColorA;
begin
  yp:=0;
  xpp:=((Src.Width-1)shl 16)div Dst.Width;

  ypp:=((Src.AbsHeight-1)shl 16)div Dst.AbsHeight;
  pc:=Pointer(Dst.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    xp:=yp shr 16;
    y1:=Src.Scanlines[xp];
    if xp<Src.AbsHeight-1 then Inc(xp);
    y2:=Src.Scanlines[xp];
    xp:=0;
    z2:=(yp and $FFFF)+1;
    iz2:=((not yp)and $FFFF)+1;
    for x:=0 to Dst.Width-1 do
    begin
      t:=xp shr 16;
      z:=xp and $FFFF;
      w2:=(iz2*z)shr 16;
      w1:=iz2-w2;
      w4:=(z2*z)shr 16;
      w3:=z2-w4;
      pc.b:=(y1[t].b*w1+y1[t+1].b*w2+y2[t].b*w3+y2[t+1].b*w4)shr 16;
      pc.g:=(y1[t].g*w1+y1[t+1].g*w2+y2[t].g*w3+y2[t+1].g*w4)shr 16;
      pc.r:=(y1[t].r*w1+y1[t+1].r*w2+y2[t].r*w3+y2[t+1].r*w4)shr 16;
      Inc(xp,xpp);
      Inc(pc);
    end;
    Inc(yp,ypp);
  end;
end;

procedure Bilinear(Src,Dst:TFastDIB);
begin
  case Dst.Bpp of
    8:  Bilinear8(Src,Dst);
    16: Bilinear16(Src,Dst);
    24: Bilinear24(Src,Dst);
    32: Bilinear32(Src,Dst);
  end;
end;

Procedure DownSize(Src, Dst: TFastDIB);
Var
  XPixSize, YPixSize, XPixShr16, YPixShr16,
  NX, EX, NY, EY, SX, SY, DX, DY, R, G, B, Count: DWord;
  DP, SP: PFColor;
Begin
  XPixSize := (Src.Width shl 16) Div Dst.Width;         // "Box" width
  YPixSize := (Src.Height shl 16) Div Dst.Height;       // "Box" Height
  XPixShr16 := XPixSize Shr 16;                         // Shortcut Values.
  YPixShr16 := YPixSize Shr 16;
  DY := 0;
  While DY < DWord(Dst.Height) Do Begin
     DX := 0;
     NY := (DY*YPixSize) shr 16;                        //Y coord of top of box in Src
     EY := NY+YPixShr16+1;                              //Y coord of bottom of box in Src
     While DX < DWord(Dst.Width) Do Begin
        NX := (DX*XPixSize) shr 16;                     //X coord of left of box in Src
        EX := NX+(XPixShr16)+1;                         //X coord of right of box in Src
        SY := NY;                                       //use Y1 to preserve NY Value
        DP := @Dst.Pixels32[DY, DX];
        R := 0; G := 0; B := 0;                         //Init Pixel content vars to zero.
        While SY < EY Do Begin
           SX := NX;
           While SX < EX Do Begin
              SP := @Src.Pixels32[SY, SX];
              Inc(B, SP.b);                             //
              Inc(G, SP.g);                             // SLOW!
              Inc(R, SP.r);                             // Speedups? God Knows.
              Inc(SX);                                  //
           End;
           Inc(SY);
        End;
        Count := (EX-NX)*(EY-NY);
        DP.b := B Div Count;                            // Too many DIVs here.
        DP.g := G Div Count;
        DP.r := R Div Count;
        Inc(DX);
     End;
     Inc(DY);
  End;
End;

procedure SmoothResize(abmp, bBmp: TFastDIB);
var
  xscale, yscale         : Extended;
  sfrom_y, sfrom_x       : Extended;
  ifrom_y, ifrom_x       : Integer;
  to_y, to_x             : Integer;
  weight_x, weight_y     : array[0..1] of Extended;
  weight                 : Extended;
  new_red, new_green     : Integer;
  new_blue               : Integer;
  total_red, total_green : Extended;
  total_blue             : Extended;
  ix, iy                 : Integer;
  sli, slo               : pLine24;
begin

  xscale := bBmp.Width / (aBmp.Width-1);
  yscale := bBmp.AbsHeight / (aBmp.AbsHeight-1);

  for to_y := 0 to bBmp.AbsHeight-1 do begin

     sfrom_y := to_y / yscale;
     ifrom_y := Trunc(sfrom_y);
     weight_y[1] := sfrom_y - ifrom_y;
     weight_y[0] := 1 - weight_y[1];

     for to_x := 0 to bBmp.Width-1 do begin

        sfrom_x := to_x / xscale;
        ifrom_x := Trunc(sfrom_x);
        weight_x[1] := sfrom_x - ifrom_x;
        weight_x[0] := 1 - weight_x[1];

        total_red   := 0.0;
        total_green := 0.0;
        total_blue  := 0.0;

        for ix := 0 to 1 do begin
           for iy := 0 to 1 do begin

              sli := abmp.Scanlines[ifrom_y + iy];
              new_red := sli[ifrom_x + ix].r;
              new_green := sli[ifrom_x + ix].g;
              new_blue := sli[ifrom_x + ix].b;

              weight := weight_x[ix] * weight_y[iy];

              total_red   := total_red   + new_red   * weight;
              total_green := total_green + new_green * weight;
              total_blue  := total_blue  + new_blue  * weight;

           end;
        end;

        slo := bBmp.ScanLines[to_y];

        slo[to_x].r := Round(total_red);
        slo[to_x].g := Round(total_green);
        slo[to_x].b := Round(total_blue);

     end;

  end;

end;

end.

