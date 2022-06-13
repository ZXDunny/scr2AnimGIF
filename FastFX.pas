unit FastFX; // FastFX
             // Updated: 5/10/2001
interface    // http://gfody.com

{$R-}

uses Windows, FastDIB;

type

  TLut  = array[Byte]of Byte;    PLut  =^TLut;
  TWLut = array[Word]of Word;    PWLut =^TWLut;
  TSLut = array[Word]of Integer; PSLut =^TSLut;

  PSaturationLut =^TSaturationLut;
  TSaturationLut = record
    Grays: array[0..767]of Integer;
    Alpha: array[Byte]of Word;
  end;

  PNormal =^TNormal;
  TNormal = record
    x,y: Shortint;
  end;

procedure FillLut(var Lut:TLut;x1,y1,x2,y2:Byte);
function  ContrastLut(Amount:Integer):TLut;
function  LightnessLut(Amount:Integer):TLut;
function  AdditionLut(Amount:Integer):TLut;
function  GammaLut(Amount:Extended):TLut;
function  MergeLuts(Luts:array of TLut):TLut;
function  MergeWLuts(Luts:array of TWLut):TWLut;
function  MakeWLut(Bmp:TFastDIB;RLut,GLut,BLut:TLut):TWLut;//for ApplyLut16
procedure ApplyWLut(Bmp:TFastDIB;Lut:TWLut);//16 only
procedure ApplyLutB(Bmp:TFastDIB;Lut:TLut);
procedure ApplyLut(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
procedure AutoContrastB(Bmp:TFastDIB);
procedure AutoContrast(Bmp:TFastDIB);
procedure Addition(Bmp:TFastDIB;r,g,b:Integer);//ApplyLut
procedure Gamma(Bmp:TFastDIB;r,g,b:Extended);//ApplyLut
procedure Contrast(Bmp:TFastDIB;r,g,b:Integer);//ApplyLut
procedure Lightness(Bmp:TFastDIB;r,g,b:Integer);//ApplyLut
function  SaturationLut(Amount:Integer):TSaturationLut;
function  MakeSaturationWLut(Bmp:TFastDIB;SLut:TSaturationLut):TWLut;
procedure ApplySaturationLut(Bmp:TFastDIB;Lut:TSaturationLut);
procedure ApplySaturationLutEx(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
procedure Saturation(Bmp:TFastDIB;Amount:Integer);
procedure Invert(Bmp:TFastDIB);
procedure AddNoise(Bmp:TFastDIB;Amount:Byte;Mono:Boolean);
procedure Grayscale(Src,Dst:TFastDIB);
procedure FastTile(Src,Dst:TFastDIB);
procedure BumpImage(Dst,Bump,Light:TFastDIB;x,y:Integer);
procedure RenderLightmap(Bmp:TFastDIB;Size:Integer);

procedure SplitBlur(Bmp:TFastDIB;Split:Integer);
procedure SplitConvolve(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
procedure BlurEdges(Bmp:TFastDIB;Split:Integer);//SplitConvolve
procedure BleedEdges(Bmp:TFastDIB;Split:Integer);//SplitConvolve
procedure Sharpen(Bmp:TFastDIB;Split:Integer);//SplitConvolve
procedure SharpenMore(Bmp:TFastDIB;Split:Integer);//SplitConvolve
procedure EmbossEdges(Bmp:TFastDIB;Split:Integer);//SplitConvolve
procedure QuickSoft(Bmp:TFastDIB);
procedure QuickSharp(Bmp:TFastDIB);
procedure QuickEmboss(Bmp:TFastDIB);
procedure Lines(Bmp:TFastDIB;Lut:TLut);
procedure Mosaic(Bmp:TFastDIB;xAmount,yAmount:Integer);//bpp > 4
procedure Shift(Bmp:TFastDIB;xAmount,yAmount:Integer);//bpp > 4
procedure AvgFrames(Dst:TFastDIB;Src:array of TFastDIB;Count:Integer);

procedure Flip(Bmp:TFastDIB);
procedure Flop(Bmp:TFastDIB);
procedure Rotate90CW(Src,Dst:TFastDIB);
procedure Rotate90CCW(Src,Dst:TFastDIB);
procedure Rotate180(Src,Dst:TFastDIB);
procedure RotateSize(Src,Dst:TFastDIB;Angle:Double);
procedure Transform(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
procedure Rotate(Src,Dst:TFastDIB;Angle:Double;Smooth:Boolean);
procedure Rotozoom(Src,Dst:TFastDIB;Angle:Double;Zoom:Integer;Smooth:Boolean);
procedure SquareWave(Src,Dst:TFastDIB;x,y,z:Double);//bpp > 4
procedure RoundWave(Src,Dst:TFastDIB;x,y,z:Double);//bpp > 4

implementation

procedure FillLut(var Lut:TLut;x1,y1,x2,y2:Byte);
var
  x,n,i,ii: Integer;
begin
  n:=x2-x1;
  if n<>0 then
  begin
    i:=y1 shl 16;
    ii:=((y2-y1+1)shl 16)div n;
    for x:=x1 to x2 do
    begin
      Lut[x]:=i shr 16;
      Inc(i,ii);
    end;
  end;
end;

function ContrastLut(Amount:Integer):TLut;
begin
  if Amount<0 then FillLut(Result,0,-Amount,255,255+Amount)else
  begin
    if Amount>255 then Amount:=255;
    FillChar(Result,Amount,0);
    FillLut(Result,Amount,0,255-Amount,255);
    FillChar(Result[256-Amount],Amount,255);
  end;
end;

function LightnessLut(Amount:Integer):TLut;
begin
  if Amount<0 then FillLut(Result,0,0,255,255+Amount)else
  begin
    if Amount>255 then Amount:=255;
    FillLut(Result,0,Amount,255,255);
  end;
end;

function AdditionLut(Amount:Integer):TLut;
var
  i,x: Integer;
begin
  if Amount<0 then
  begin
    if Amount<-255 then Amount:=-255;
    FillChar(Result,-Amount,0);
    x:=0;
    for i:=-Amount to 255 do
    begin
      Result[i]:=x;
      Inc(x);
    end;
  end else if Amount>0 then
  begin
    if Amount>255 then Amount:=255;
    x:=Amount;
    for i:=0 to 255-Amount do
    begin
      Result[i]:=x;
      Inc(x);
    end;
    FillChar(Result[256-Amount],Amount,255);
  end else for i:=0 to 255 do Result[i]:=i;
end;

function GammaLut(Amount:Extended):TLut;
var
  i,z: Integer;
  y:   Extended;
begin
  if Amount>0 then
  begin
    Result[0]:=0;
    y:=1/Amount;
    for i:=1 to 255 do
    begin
      z:=Round(255*Exp(y*Ln(i/255)));
      if z>255 then z:=255 else if z<0 then z:=0;
      Result[i]:=z;
    end;
  end;
end;

function MergeLuts(Luts:array of TLut):TLut;
var
  x,y,z: Integer;
begin
  x:=Low(Luts);
  for y:=0 to 255 do
    Result[y]:=Luts[x,y];
  for z:=x+1 to High(Luts) do
  for y:=0 to 255 do
    Result[y]:=Luts[z,Result[y]];
end;

function MergeWLuts(Luts:array of TWLut):TWLut;
var
  x,y,z: Integer;
begin
  x:=Low(Luts);
  for y:=0 to 65535 do
    Result[y]:=Luts[x,y];
  for z:=x+1 to High(Luts) do
  for y:=0 to 65535 do
    Result[y]:=Luts[z,Result[y]];
end;

function MakeWLut(Bmp:TFastDIB;RLut,GLut,BLut:TLut):TWLut;
var
  i: Integer;
begin
  for i:=0 to 65535 do
    Result[i]:=
      RLut[Scale8(i and Bmp.RMask shr Bmp.RShl,Bmp.Bpr)]shr Bmp.RShr shl Bmp.RShl or
      GLut[Scale8(i and Bmp.GMask shr Bmp.GShl,Bmp.Bpg)]shr Bmp.GShr shl Bmp.GShl or
      BLut[Scale8(i and Bmp.BMask,Bmp.Bpr)]shr Bmp.BShr;
end;

procedure ApplyWLut(Bmp:TFastDIB;Lut:TWLut);
var
  pw:  PWord;
  x,y: Integer;
begin
  pw:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      pw^:=Lut[pw^];
      Inc(pw);
    end;
    pw:=Ptr(Integer(pw)+Bmp.Gap);
  end;
end;

procedure ApplyLutB(Bmp:TFastDIB;Lut:TLut);
var
  pb: PByte;
  x,y: Integer;
begin
  pb:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.BWidth-Bmp.Gap-1 do
    begin
      pb^:=Lut[pb^];
      Inc(pb);
    end;
    Inc(pb,Bmp.Gap);
  end;
end;

procedure ApplyLut8(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
var
  i:  Integer;
  pa: PFColorA;
begin
  pa:=Pointer(Bmp.Colors);
  for i:=0 to (1 shl Bmp.Bpp)-1 do
  begin
    pa.b:=BLut[pa.b];
    pa.g:=GLut[pa.g];
    pa.r:=RLut[pa.r];
    Inc(pa);
  end;
  if Bmp.hDC<>0 then Bmp.UpdateColors;
end;

procedure ApplyLut16(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
begin
  ApplyWLut(Bmp,MakeWLut(Bmp,RLut,GLut,BLut));
end;

procedure ApplyLut24(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
var
  pc:  PFColor;
  x,y: Integer;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      pc.b:=BLut[pc.b];
      pc.g:=GLut[pc.g];
      pc.r:=RLut[pc.r];
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplyLut32(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
var
  pc: PFColorA;
  x,y: Integer;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      pc.b:=BLut[pc.b];
      pc.g:=GLut[pc.g];
      pc.r:=RLut[pc.r];
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplyLut(Bmp:TFastDIB;RLut,GLut,BLut:TLut);
begin
  case Bmp.Bpp of
    1,4,8: ApplyLut8(Bmp,RLut,GLut,BLut);
    16: ApplyLut16(Bmp,RLut,GLut,BLut);
    24: ApplyLut24(Bmp,RLut,GLut,BLut);
    32: ApplyLut32(Bmp,RLut,GLut,BLut);
  end;
end;

procedure AutoContrastB(Bmp:TFastDIB);
var
  Lut: TLut;
  pb: PByte;
  hi,lo: Byte;
  x,y: Integer;
begin
  hi:=0; lo:=255;
  pb:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      if pb^ > hi then hi:=pb^;
      if pb^ < lo then lo:=pb^;
      Inc(pb);
    end;
    Inc(pb,Bmp.Gap);
  end;
  if(lo<>0)or(hi<>255)then
  begin
    FillLut(Lut,lo,0,hi,255);
    ApplyLutB(Bmp,Lut);
  end;
end;

procedure AutoContrast8(Bmp:TFastDIB);
var
  hr,hg,hb,lr,lg,lb: Byte;
  r,g,b: TLut;
  pa: PFColorA;
  i: Integer;
begin
  hr:=0; hg:=0; hb:=0;
  lr:=255; lg:=255; lb:=255;
  pa:=Pointer(Bmp.Colors);
  for i:=0 to (1 shl Bmp.Bpp)-1 do
  begin
    if pa.b>hb then hb:=pa.b;
    if pa.b<lb then lb:=pa.b;
    if pa.g>hg then hg:=pa.g;
    if pa.g<lg then lg:=pa.g;
    if pa.r>hr then hr:=pa.r;
    if pa.r<lr then lr:=pa.r;
    Inc(pa);
  end;
  if((lr or lg or lb)<>0)or((hr and hg and hb)<>255)then
  begin
    FillLut(r,lr,0,hr,255);
    FillLut(g,lg,0,hg,255);
    FillLut(b,lb,0,hb,255);
    ApplyLut8(Bmp,r,g,b);
  end;
end;

procedure AutoContrast16(Bmp:TFastDIB);
var
  hr,hg,hb,lr,lg,lb,rr,gg,bb: Byte;
  r,g,b: TLut;
  x,y: Integer;
  pw: PWord;
begin
  hr:=0; hg:=0; hb:=0;
  lr:=255; lg:=255; lb:=255;
  pw:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      bb:=pw^ and Bmp.BMask;
      gg:=pw^ and Bmp.GMask shr Bmp.GShl;
      rr:=pw^ and Bmp.RMask shr Bmp.RShl;
      if bb>hb then hb:=bb;
      if bb<lb then lb:=bb;
      if gg>hg then hg:=gg;
      if gg<lg then lg:=gg;
      if rr>hr then hr:=rr;
      if rr<lr then lr:=rr;
      Inc(pw);
    end;
    pw:=Ptr(Integer(pw)+Bmp.Gap);
  end;
  lr:=Scale8(lr,Bmp.Bpr);
  hr:=Scale8(hr,Bmp.Bpr);
  lg:=Scale8(lg,Bmp.Bpg);
  hg:=Scale8(hg,Bmp.Bpg);
  lb:=Scale8(lb,Bmp.Bpb);
  hb:=Scale8(hb,Bmp.Bpb);
  if((lr or lg or lb)<>0)or((hr and hg and hb)<>255)then
  begin
    FillLut(r,lr,0,hr,255);
    FillLut(g,lg,0,hg,255);
    FillLut(b,lb,0,hb,255);
    ApplyWLut(Bmp,MakeWLut(Bmp,r,g,b));
  end;
end;

procedure AutoContrast24(Bmp:TFastDIB);
var
  hr,hg,hb,lr,lg,lb: Byte;
  r,g,b: TLut;
  x,y: Integer;
  pc: PFColor;
begin
  hr:=0; hg:=0; hb:=0;
  lr:=255; lg:=255; lb:=255;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      if pc.b>hb then hb:=pc.b;
      if pc.b<lb then lb:=pc.b;
      if pc.g>hg then hg:=pc.g;
      if pc.g<lg then lg:=pc.g;
      if pc.r>hr then hr:=pc.r;
      if pc.r<lr then lr:=pc.r;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
  if((lr or lg or lb)<>0)or((hr and hg and hb)<>255)then
  begin
    FillLut(r,lr,0,hr,255);
    FillLut(g,lg,0,hg,255);
    FillLut(b,lb,0,hb,255);
    ApplyLut24(Bmp,r,g,b);
  end;
end;

procedure AutoContrast32(Bmp:TFastDIB);
var
  hr,hg,hb,lr,lg,lb: Byte;
  r,g,b: TLut;
  pc: PFColorA;
  x,y: Integer;
begin
  hr:=0; hg:=0; hb:=0;
  lr:=255; lg:=255; lb:=255;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      if pc.b>hb then hb:=pc.b;
      if pc.b<lb then lb:=pc.b;
      if pc.g>hg then hg:=pc.g;
      if pc.g<lg then lg:=pc.g;
      if pc.r>hr then hr:=pc.r;
      if pc.r<lr then lr:=pc.r;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
  if((lr or lg or lb)<>0)or((hr and hg and hb)<>255)then
  begin
    FillLut(r,lr,0,hr,255);
    FillLut(g,lg,0,hg,255);
    FillLut(b,lb,0,hb,255);
    ApplyLut32(Bmp,r,g,b);
  end;
end;

procedure AutoContrast(Bmp:TFastDIB);
begin
  case Bmp.Bpp of
    1,4,8: AutoContrast8(Bmp);
    16: AutoContrast16(Bmp);
    24: AutoContrast24(Bmp);
    32: AutoContrast32(Bmp);
  end;
end;

procedure Addition(Bmp:TFastDIB;r,g,b:Integer);
begin
  ApplyLut(Bmp,
    AdditionLut(r),
    AdditionLut(g),
    AdditionLut(b));
end;

procedure Gamma(Bmp:TFastDIB;r,g,b:Extended);
begin
  ApplyLut(Bmp,
    GammaLut(r),
    GammaLut(g),
    GammaLut(b));
end;

procedure Contrast(Bmp:TFastDIB;r,g,b:Integer);
begin
  ApplyLut(Bmp,
    ContrastLut(r),
    ContrastLut(g),
    ContrastLut(b));
end;

procedure Lightness(Bmp:TFastDIB;r,g,b:Integer);
begin
  ApplyLut(Bmp,
    LightnessLut(r),
    LightnessLut(g),
    LightnessLut(b));
end;

function SaturationLut(Amount:Integer):TSaturationLut;
var
  x,y,i: Integer;
begin
  x:=0;
  for i:=1 to 256 do
    Result.Alpha[i-1]:=(i*Amount)shr 8;
  for i:=1 to 256 do
  begin
    y:=i-Result.Alpha[i-1];
    Result.Grays[x]:=y; Inc(x);
    Result.Grays[x]:=y; Inc(x);
    Result.Grays[x]:=y; Inc(x);
  end;
end;

function MakeSaturationWLut(Bmp:TFastDIB;SLut:TSaturationLut):TWLut;
var
  Gray,i,z: Integer;
  r,g,b:    Byte;
begin
  for i:=0 to 65535 do
  begin
    b:=Scale8(i and Bmp.BMask,Bmp.Bpb);
    g:=Scale8(i and Bmp.GMask shr Bmp.GShl,Bmp.Bpg);
    r:=Scale8(i and Bmp.RMask shr Bmp.RShl,Bmp.Bpr);
    Gray:=SLut.Grays[r+g+b];
    z:=Gray+SLut.Alpha[r]; if z>255 then z:=255 else if z<0 then z:=0; r:=z;
    z:=Gray+SLut.Alpha[g]; if z>255 then z:=255 else if z<0 then z:=0; g:=z;
    z:=Gray+SLut.Alpha[b]; if z>255 then z:=255 else if z<0 then z:=0; b:=z;
    Result[i]:=b shr Bmp.BShr or g shr Bmp.GShr shl Bmp.GShl or r shr Bmp.RShr shl Bmp.RShl;
  end;
end;

procedure ApplySaturationLut8(Bmp:TFastDIB;Lut:TSaturationLut);
var
  g,z,c: Integer;
  pa:    PFColorA;
begin
  pa:=Pointer(Bmp.Colors);
  for c:=0 to(1 shl Bmp.Bpp)-1 do
  begin
    g:=Lut.Grays[pa.b+pa.g+pa.r];
    z:=Lut.Alpha[pa.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.b:=z;
    z:=Lut.Alpha[pa.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.g:=z;
    z:=Lut.Alpha[pa.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.r:=z;
    Inc(pa);
  end;
  if Bmp.hDC<>0 then Bmp.UpdateColors;
end;

procedure ApplySaturationLut16(Bmp:TFastDIB;Lut:TSaturationLut);
begin
  ApplyWLut(Bmp,MakeSaturationWLut(Bmp,Lut));
end;

procedure ApplySaturationLut24(Bmp:TFastDIB;Lut:TSaturationLut);
var
  x,y,g,z: Integer;
  pc: PFColor;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      g:=Lut.Grays[pc.b+pc.g+pc.r];
      z:=Lut.Alpha[pc.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.b:=z;
      z:=Lut.Alpha[pc.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.g:=z;
      z:=Lut.Alpha[pc.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.r:=z;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplySaturationLut32(Bmp:TFastDIB;Lut:TSaturationLut);
var
  g,x,y,z: Integer;
  pc: PFColorA;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      g:=Lut.Grays[pc.b+pc.g+pc.r];
      z:=Lut.Alpha[pc.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.b:=z;
      z:=Lut.Alpha[pc.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.g:=z;
      z:=Lut.Alpha[pc.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.r:=z;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplySaturationLut(Bmp:TFastDIB;Lut:TSaturationLut);
begin
  case Bmp.Bpp of
    1,4,8: ApplySaturationLut8(Bmp,Lut);
    16: ApplySaturationLut16(Bmp,Lut);
    24: ApplySaturationLut24(Bmp,Lut);
    32: ApplySaturationLut32(Bmp,Lut);
  end;
end;

procedure ApplySaturationLutEx8(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
var
  pa: PFColorA;
  g,c,z: Integer;
begin
  pa:=Pointer(Bmp.Colors);
  for c:=0 to(1 shl Bmp.Bpp)-1 do
  begin
    g:=Lut.Grays[pa.b+pa.g+pa.r];
    z:=Lut.Alpha[pa.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.b:=BLut[z];
    z:=Lut.Alpha[pa.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.g:=GLut[z];
    z:=Lut.Alpha[pa.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pa.r:=RLut[z];
    Inc(pa);
  end;
  if Bmp.hDC<>0 then Bmp.UpdateColors;
end;

procedure ApplySaturationLutEx16(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
begin
  ApplyWLut(Bmp,MergeWLuts([MakeSaturationWLut(Bmp,Lut),MakeWLut(Bmp,RLut,GLut,BLut)]));
end;

procedure ApplySaturationLutEx24(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
var
  x,y,g,z: Integer;
  pc: PFColor;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      g:=Lut.Grays[pc.b+pc.g+pc.r];
      z:=Lut.Alpha[pc.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.b:=BLut[z];
      z:=Lut.Alpha[pc.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.g:=GLut[z];
      z:=Lut.Alpha[pc.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.r:=RLut[z];
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplySaturationLutEx32(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
var
  g,x,y,z: Integer;
  pc: PFColorA;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      g:=Lut.Grays[pc.b+pc.g+pc.r];
      z:=Lut.Alpha[pc.b]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.b:=BLut[z];
      z:=Lut.Alpha[pc.g]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.g:=GLut[z];
      z:=Lut.Alpha[pc.r]+g; if z>255 then z:=255 else if z<0 then z:=0; pc.r:=RLut[z];
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure ApplySaturationLutEx(Bmp:TFastDIB;Lut:TSaturationLut;RLut,GLut,BLut:TLut);
begin
  case Bmp.Bpp of
    1,4,8: ApplySaturationLutEx8(Bmp,Lut,RLut,GLut,BLut);
    16: ApplySaturationLutEx16(Bmp,Lut,RLut,GLut,BLut);
    24: ApplySaturationLutEx24(Bmp,Lut,RLut,GLut,BLut);
    32: ApplySaturationLutEx32(Bmp,Lut,RLut,GLut,BLut);
  end;
end;

procedure Saturation(Bmp:TFastDIB;Amount:Integer);
begin
  ApplySaturationLut(Bmp,SaturationLut(Amount));
end;

procedure InvertMem(Mem:Pointer;Size:Integer);
asm
  {$IFNDEF CPUx64}
  push esi
  mov ecx,edx
  mov esi,eax
  shr ecx,2
  jz @exit
  @dwords:
    mov eax,[esi]
    xor eax,-1
    mov [esi],eax
    add esi,4
    dec ecx
  jnz @dwords
  and edx,3
  mov ecx,edx
  jz @exit
  @bytes:
    movzx eax,Byte([esi])
    xor eax,-1
    mov [esi],al
    inc esi
    dec ecx
  jnz @bytes
  @exit:
  pop esi
  {$ENDIF}
end;

procedure Invert(Bmp:TFastDIB);
var
  i: Integer;
begin
  if Bmp.Size<>0 then InvertMem(Bmp.Bits,Bmp.Size) else
  begin
    for i:=0 to Bmp.AbsHeight-1 do
      InvertMem(Bmp.Scanlines[i],Bmp.BWidth-Bmp.Gap);
  end;
end;

procedure AddNoise8(Bmp:TFastDIB;Amount:Integer);
var
  x,y,i,a: Integer;
  pb: PByte;
begin
  i:=Amount shr 1;
  pb:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-1 do
    begin
      a:=pb^+Random(Amount)-i;
      if a>255 then pb^:=255 else if a<0 then pb^:=0 else pb^:=a;
      Inc(pb);
    end;
    Inc(pb,Bmp.Gap);
  end;
end;

procedure AddNoise16(Bmp:TFastDIB;Amount:Integer;Mono:Boolean);
var
  z,a,i,x,y: Integer;
  pw: PWord;
  wd: Word;
begin
  i:=(Amount shr 1)+1;
  pw:=Pointer(Bmp.Bits);
  if Mono then
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        a:=Random(Amount)-i;
        z:=Integer((pw^ and Bmp.BMask+1)shl Bmp.BShr)+a;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=z shr Bmp.BShr;
        z:=Integer((pw^ and Bmp.GMask shr Bmp.GShl+1)shl Bmp.GShr)+a;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=wd or(z shr Bmp.GShr shl Bmp.GShl);
        z:=Integer((pw^ and Bmp.RMask shr Bmp.RShl+1)shl Bmp.RShr)+a;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=wd or(z shr Bmp.RShr shl Bmp.RShl);
        pw^:=wd; Inc(pw);
      end;
      pw:=Ptr(Integer(pw)+Bmp.Gap);
    end;
  end else
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        z:=Integer((pw^ and Bmp.BMask+1)shl Bmp.BShr)+Random(Amount)-i;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=z shr Bmp.BShr;
        z:=Integer((pw^ and Bmp.GMask shr Bmp.GShl+1)shl Bmp.GShr)+Random(Amount)-i;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=wd or(z shr Bmp.GShr shl Bmp.GShl);
        z:=Integer((pw^ and Bmp.RMask shr Bmp.RShl+1)shl Bmp.RShr)+Random(Amount)-i;
        if z>255 then z:=255 else if z<0 then z:=0;
        wd:=wd or(z shr Bmp.RShr shl Bmp.RShl);
        pw^:=wd; Inc(pw);
      end;
      pw:=Ptr(Integer(pw)+Bmp.Gap);
    end;
  end;
end;

procedure AddNoise24(Bmp:TFastDIB;Amount:Integer;Mono:Boolean);
var
  i,z,a,x,y: Integer;
  pc: PFColor;
begin
  i:=Amount shr 1;
  pc:=Pointer(Bmp.Bits);
  if Mono then
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        a:=Random(Amount)-i;
        z:=pc.b+a; if z>255 then pc.b:=255 else if z<0 then pc.b:=0 else pc.b:=z;
        z:=pc.g+a; if z>255 then pc.g:=255 else if z<0 then pc.g:=0 else pc.g:=z;
        z:=pc.r+a; if z>255 then pc.r:=255 else if z<0 then pc.r:=0 else pc.r:=z;
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Bmp.Gap);
    end;
  end else
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        z:=pc.b+Random(Amount)-i;
        if z>255 then pc.b:=255 else if z<0 then pc.b:=0 else pc.b:=z;
        z:=pc.g+Random(Amount)-i;
        if z>255 then pc.g:=255 else if z<0 then pc.g:=0 else pc.g:=z;
        z:=pc.r+Random(Amount)-i;
        if z>255 then pc.r:=255 else if z<0 then pc.r:=0 else pc.r:=z;
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Bmp.Gap);
    end;
  end;
end;

procedure AddNoise32(Bmp:TFastDIB;Amount:Integer;Mono:Boolean);
var
  s,a,z,x,y: Integer;
  pa: PFColorA;
begin
  s:=Amount shr 1;
  pa:=Pointer(Bmp.Bits);
  if Mono then
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        a:=Random(Amount)-s;
        z:=pa.b+a; if z>255 then pa.b:=255 else if z<0 then pa.b:=0 else pa.b:=z;
        z:=pa.g+a; if z>255 then pa.g:=255 else if z<0 then pa.g:=0 else pa.g:=z;
        z:=pa.r+a; if z>255 then pa.r:=255 else if z<0 then pa.r:=0 else pa.r:=z;
        Inc(pa);
      end;
      pa:=Ptr(Integer(pa)+Bmp.Gap);
    end;
  end else
  begin
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        z:=pa.b+Random(Amount)-s;
        if z>255 then pa.b:=255 else if z<0 then pa.b:=0 else pa.b:=z;
        z:=pa.g+Random(Amount)-s;
        if z>255 then pa.g:=255 else if z<0 then pa.g:=0 else pa.g:=z;
        z:=pa.r+Random(Amount)-s;
        if z>255 then pa.r:=255 else if z<0 then pa.r:=0 else pa.r:=z;
        Inc(pa);
      end;
      pa:=Ptr(Integer(pa)+Bmp.Gap);
    end;
  end;
end;

procedure AddNoise(Bmp:TFastDIB;Amount:Byte;Mono:Boolean);
begin
  case Bmp.Bpp of
    8:  AddNoise8(Bmp,Amount);
    16: AddNoise16(Bmp,Amount,Mono);
    24: AddNoise24(Bmp,Amount,Mono);
    32: AddNoise32(Bmp,Amount,Mono);
  end;
end;

procedure Grayscale8(Src,Dst:TFastDIB);
var
  Div3: TLut;
  x,y: Integer;
  c: TFColorA;
  pb,pc: PByte;
begin
  FillLut(Div3,0,0,255,255 div 3);
  pb:=Pointer(Dst.Bits);
  pc:=Pointer(Src.Bits);

  for y:=0 to Dst.AbsHeight-1 do
  begin
    for x:=0 to Dst.Width-1 do
    begin
      c:=Src.Colors[pc^];
      pb^:=Div3[c.b]+Div3[c.g]+Div3[c.r];
      Inc(pb);
      Inc(pc);
    end;
    Inc(pb,Dst.Gap);
    Inc(pc,Src.Gap);
  end;
end;

procedure Grayscale16(Src,Dst:TFastDIB);
var
  Div3: TLut;
  Lut: TWLut;
  x,y: Integer;
  pw: PWord;
  pb: PByte;
begin
  FillLut(Div3,0,0,255,255 div 3);
  for x:=0 to 65535 do
    Lut[x]:=Div3[Scale8(x and Src.BMask,Src.Bpb)]+
            Div3[Scale8(x and Src.GMask shr Src.GShl,Src.Bpg)]+
            Div3[Scale8(x and Src.RMask shr Src.RShl,Src.Bpr)];

  pb:=Pointer(Dst.Bits);
  pw:=Pointer(Src.Bits);
  for y:=0 to Dst.AbsHeight-1 do
  begin
    for x:=0 to Dst.Width-1 do
    begin
      pb^:=Lut[pw^];
      Inc(pb);
      Inc(pw);
    end;
    Inc(pb,Dst.Gap);
    pw:=Ptr(Integer(pw)+Src.Gap);
  end;
end;

procedure Grayscale24(Src,Dst:TFastDIB);
var
  Div3: TLut;
  x,y: Integer;
  pb: PByte;
  pc: PFColor;
begin
  FillLut(Div3,0,0,255,255 div 3);
  pb:=Pointer(Dst.Bits);
  pc:=Pointer(Src.Bits);

  for y:=0 to Dst.AbsHeight-1 do
  begin
    for x:=0 to Dst.Width-1 do
    begin
      pb^:=Div3[pc.b]+Div3[pc.g]+Div3[pc.r];
      Inc(pb);
      Inc(pc);
    end;
    Inc(pb,Dst.Gap);
    pc:=Ptr(Integer(pc)+Src.Gap);
  end;
end;

procedure Grayscale32(Src,Dst:TFastDIB);
var
  Div3: TLut;
  x,y: Integer;
  pb: PByte;
  pc: PFColorA;
begin
  FillLut(Div3,0,0,255,255 div 3);
  pb:=Pointer(Dst.Bits);
  pc:=Pointer(Src.Bits);

  for y:=0 to Dst.AbsHeight-1 do
  begin
    for x:=0 to Dst.Width-1 do
    begin
      pb^:=Div3[pc.b]+Div3[pc.g]+Div3[pc.r];
      Inc(pb);
      Inc(pc);
    end;
    Inc(pb,Dst.Gap);
    pc:=Ptr(Integer(pc)+Src.Gap);
  end;
end;

procedure Grayscale(Src,Dst:TFastDIB);
begin
  Dst.SetSize(Src.Width,Src.Height,8);
  Dst.FillColors(0,255,[tfBlack,tfWhite]);
  case Src.Bpp of
    8:  Grayscale8(Src,Dst);
    16: Grayscale16(Src,Dst);
    24: Grayscale24(Src,Dst);
    32: Grayscale32(Src,Dst);
  end;
end;

procedure FastTile(Src,Dst:TFastDIB);
var
  wd,hd: Integer;
begin
  wd:=Src.Width;
  hd:=Src.AbsHeight;
  Dst.CopyRect(Src,0,0,Src.Width,Src.AbsHeight,0,0);
  while wd<Dst.Width do
  begin
    Dst.CopyRect(Dst,wd,0,wd shl 1,Src.AbsHeight,0,0);
    Inc(wd,wd);
  end;
  while hd<Dst.AbsHeight do
  begin
    Dst.CopyRect(Dst,0,hd,Dst.Width,hd shl 1,0,0);
    Inc(hd,hd);
  end;
end;

procedure BumpImage16(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  bm: PNormal;
  pw: PWord;
begin
  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pw:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
        pw^:=Light.Pixels16[by,bx]
      else pw^:=0;
      Inc(bm);
      Inc(pw);
    end;
  end;
end;

procedure BumpImage24(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  bm: PNormal;
  pc: PFColor;
begin
  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pc:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
        pc^:=Light.Pixels24[by,bx]
      else pc^:=tfBlack;
      Inc(bm);
      Inc(pc);
    end;
  end;
end;

procedure BumpImage32(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  bm: PNormal;
  pc: PFColorA;
begin
  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pc:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
        pc^:=Light.Pixels32[by,bx]
      else pc.i:=0;
      Inc(bm);
      Inc(pc);
    end;
  end;
end;

procedure BumpImage816(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  Lut: array[Byte]of Word;
  bm: PNormal;
  pw: PWord;
begin
  for xh:=0 to 255 do
    Lut[xh]:=xh shr Dst.BShr or
             xh shr Dst.GShr shl Dst.GShl or
             xh shr Dst.RShr shl Dst.RShl;

  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pw:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
        pw^:=Lut[Light.Pixels8[by,bx]]
      else pw^:=0;
      Inc(bm);
      Inc(pw);
    end;
  end;
end;

procedure BumpImage824(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  bm: PNormal;
  pc: PFColor;
  c: Byte;
begin
  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pc:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
      begin
        c:=Light.Pixels8[by,bx];
        pc.b:=c;
        pc.g:=c;
        pc.r:=c;
      end else pc^:=tfBlack;
      Inc(bm);
      Inc(pc);
    end;
  end;
end;

procedure BumpImage832(Dst,Bump,Light:TFastDIB;x,y:Integer);
var
  xh,yh,x2,y2,y3,bx,by: Integer;
  bm: PNormal;
  pc: PFColorA;
  c: Byte;
begin
  xh:=Light.Width shr 1;
  yh:=Light.AbsHeight shr 1;

  for y2:=0 to Dst.AbsHeight-1 do
  begin
    bm:=Bump.Scanlines[y2];
    pc:=Dst.Scanlines[y2];

    y3:=yh+y2-y;
    for x2:=0 to Dst.Width-1 do
    begin
      bx:=bm.x+xh+x2-x;
      by:=bm.y+y3;

      if(bx<Light.Width)and(bx>0)and(by<Light.AbsHeight)and(by>0)then
      begin
        c:=Light.Pixels8[by,bx];
        pc.b:=c;
        pc.g:=c;
        pc.r:=c;
      end else pc.i:=0;
      Inc(bm);
      Inc(pc);
    end;
  end;
end;

procedure BumpImage(Dst,Bump,Light:TFastDIB;x,y:Integer);
begin
  if Light.Bpp=8 then
  begin
    case Dst.Bpp of
      16: BumpImage816(Dst,Bump,Light,x,y);
      24: BumpImage824(Dst,Bump,Light,x,y);
      32: BumpImage832(Dst,Bump,Light,x,y);
    end;
  end else
  begin
    case Dst.Bpp of
      16: BumpImage16(Dst,Bump,Light,x,y);
      24: BumpImage24(Dst,Bump,Light,x,y);
      32: BumpImage32(Dst,Bump,Light,x,y);
    end;
  end;
end;

procedure RenderLightmap8(Bmp:TFastDIB;Size:Integer);
var
  x,y,yy,f,r,i: Integer;
  pb: PByte;
begin
  r:=Size shr 1;
  f:=Round(65536/(Size/((256/(Size/2))*2)));

  pb:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    yy:=(y-r)*(y-r);
    for x:=0 to Bmp.Width-1 do
    begin
      i:=((x-r)*(x-r)+yy)*f shr 16;
      if i>255 then i:=255;
      i:=i xor -1;
      pb^:=i;
      Inc(pb);
    end;
    Inc(pb,Bmp.Gap);
  end;
end;

procedure RenderLightmap16(Bmp:TFastDIB;Size:Integer);
var
  x,y,yy,f,r,i: Integer;
  Lut: array[Byte]of Word;
  pw: PWord;
begin
  r:=Size shr 1;
  f:=Round(65536/(Size/((256/(Size/2))*2)));

  for i:=0 to 255 do
    Lut[i]:=
          i shr Bmp.RShr shl Bmp.RShl or
          i shr Bmp.GShr shl Bmp.GShl or
          i shr Bmp.BShr;

  pw:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    yy:=(y-r)*(y-r);
    for x:=0 to Bmp.Width-1 do
    begin
      i:=((x-r)*(x-r)+yy)*f shr 16;
      if i>255 then i:=255;
      pw^:=Lut[i xor $FF];
      Inc(pw);
    end;
    pw:=Ptr(Integer(pw)+Bmp.Gap);
  end;
end;

procedure RenderLightmap24(Bmp:TFastDIB;Size:Integer);
var
  x,y,yy,f,r,i: Integer;
  pc: PFColor;
begin
  r:=Size shr 1;
  f:=Round(65536/(Size/((256/(Size/2))*2)));

  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    yy:=(y-r)*(y-r);
    for x:=0 to Bmp.Width-1 do
    begin
      i:=((x-r)*(x-r)+yy)*f shr 16;
      if i>255 then i:=255;
      i:=i xor -1;
      pc.b:=i;
      pc.g:=i;
      pc.r:=i;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure RenderLightmap32(Bmp:TFastDIB;Size:Integer);
var
  x,y,yy,f,r,i: Integer;
  pc: PFColorA;
begin
  r:=Size shr 1;
  f:=Round(65536/(Size/((256/(Size/2))*2)));

  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    yy:=(y-r)*(y-r);
    for x:=0 to Bmp.Width-1 do
    begin
      i:=((x-r)*(x-r)+yy)*f shr 16;
      if i>255 then i:=255;
      i:=i xor -1;
      pc.b:=i;
      pc.g:=i;
      pc.r:=i;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure RenderLightmap(Bmp:TFastDIB;Size:Integer);
begin
  case Bmp.Bpp of
    8:  RenderLightmap8(Bmp,Size);
    16: RenderLightmap16(Bmp,Size);
    24: RenderLightmap24(Bmp,Size);
    32: RenderLightmap32(Bmp,Size);
  end;
end;

procedure SplitBlur8(Bmp:TFastDIB;Split:Integer);
var
  n,s,e,w,x,y: Integer;
  Lin1,Lin2: PLine8;
  pc: PByte;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      pc^:=(Lin1[w]+Lin1[e]+Lin2[w]+Lin2[e])shr 2;
      Inc(pc);
    end;
    Inc(pc,Bmp.Gap);
  end;
end;

procedure SplitBlur16(Bmp:TFastDIB;Split:Integer);
var
  n,s,e,w,x,y: Integer;
  Lin1,Lin2: PLine16;
  c1,c2,c3,c4: TFColor;
  ri,gi,bi: array[Byte]of Word;
  c: array[Word]of TFColor;
  pc: PWord;
begin
  for x:=0 to 65535 do
  begin
    c[x].b:=Scale8(x and Bmp.BMask,Bmp.Bpb);
    c[x].g:=Scale8(x and Bmp.GMask shr Bmp.GShl,Bmp.Bpg);
    c[x].r:=Scale8(x and Bmp.RMask shr Bmp.RShl,Bmp.Bpr);
  end;
  for x:=0 to 255 do
  begin
    bi[x]:=x shr Bmp.BShr;
    gi[x]:=x shr Bmp.GShr shl Bmp.GShl;
    ri[x]:=x shr Bmp.RShr shl Bmp.RShl;
  end;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      c1:=c[Lin1[w]]; c2:=c[Lin1[e]];
      c3:=c[Lin2[w]]; c4:=c[Lin2[e]];
      pc^:=bi[(c1.b + c2.b + c3.b + c4.b)shr 2]or
           gi[(c1.g + c2.g + c3.g + c4.g)shr 2]or
           ri[(c1.r + c2.r + c3.r + c4.r)shr 2];
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure SplitBlur24(Bmp:TFastDIB;Split:Integer);
var
  n,s,e,w,x,y: Integer;
  Lin1,Lin2: PLine24;
  pc: PFColor;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      pc.b:=(Lin1[w].b+Lin1[e].b+Lin2[w].b+Lin2[e].b)shr 2;
      pc.g:=(Lin1[w].g+Lin1[e].g+Lin2[w].g+Lin2[e].g)shr 2;
      pc.r:=(Lin1[w].r+Lin1[e].r+Lin2[w].r+Lin2[e].r)shr 2;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure SplitBlur32(Bmp:TFastDIB;Split:Integer);
var
  n,s,e,w,x,y: Integer;
  Lin1,Lin2: PLine32;
  pc: PFColorA;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      pc.b:=(Lin1[w].b+Lin1[e].b+Lin2[w].b+Lin2[e].b)shr 2;
      pc.g:=(Lin1[w].g+Lin1[e].g+Lin2[w].g+Lin2[e].g)shr 2;
      pc.r:=(Lin1[w].r+Lin1[e].r+Lin2[w].r+Lin2[e].r)shr 2;
      Inc(pc);
    end;
  end;
end;

procedure SplitBlur(Bmp:TFastDIB;Split:Integer);
begin
  case Bmp.Bpp of
    8:  SplitBlur8(Bmp,Split);
    16: SplitBlur16(Bmp,Split);
    24: SplitBlur24(Bmp,Split);
    32: SplitBlur32(Bmp,Split);
  end;
end;

procedure SplitConvolve8(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
var
  Sum,n,s,e,w,i,x,y: Integer;
  Lin1,Lin2: PLine8;
  pc: PByte;
begin
  Sum:=nw+ne+sw+se+m;
  if Sum=0 then Sum:=1;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      i:=(pc^*m+Lin1[w]*nw+Lin1[e]*ne+Lin2[w]*sw+Lin2[e]*se)div Sum;
      if i>255 then pc^:=255 else if i<0 then pc^:=0 else pc^:=i;
      Inc(pc);
    end;
    Inc(pc,Bmp.Gap);
  end;
end;

procedure SplitConvolve16(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
var
  Sum,n,s,e,w,r,g,b,x,y: Integer;
  Lin1,Lin2: PLine16;
  c: array[Word]of TFColor;
  c0,c1,c2,c3,c4: TFColor;
  ri,gi,bi: array[Byte]of Word;
  pc: PWord;
begin
  Sum:=nw+ne+sw+se+m;
  if Sum=0 then Sum:=1;
  for x:=0 to 65535 do
  begin
    c[x].b:=Scale8(x and Bmp.BMask,Bmp.Bpb);
    c[x].g:=Scale8(x and Bmp.GMask shr Bmp.GShl,Bmp.Bpg);
    c[x].r:=Scale8(x and Bmp.RMask shr Bmp.RShl,Bmp.Bpr);
  end;
  for x:=0 to 255 do
  begin
    bi[x]:=x shr Bmp.BShr;
    gi[x]:=x shr Bmp.GShr shl Bmp.GShl;
    ri[x]:=x shr Bmp.RShr shl Bmp.RShl;
  end;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      c0:=c[pc^];
      c1:=c[Lin1[w]]; c2:=c[Lin1[e]];
      c3:=c[Lin2[w]]; c4:=c[Lin2[e]];
      b:=(c0.b*m+c1.b*nw+c2.b*ne+c3.b*sw+c4.b*se)div Sum;
      if b>255 then b:=Bmp.BMask else if b<0 then b:=0 else b:=bi[b];
      g:=(c0.g*m+c1.g*nw+c2.g*ne+c3.g*sw+c4.g*se)div Sum;
      if g>255 then g:=Bmp.GMask else if g<0 then g:=0 else g:=gi[g];
      r:=(c0.r*m+c1.r*nw+c2.r*ne+c3.r*sw+c4.r*se)div Sum;
      if r>255 then r:=Bmp.RMask else if r<0 then r:=0 else r:=ri[r];
      pc^:=b or g or r;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure SplitConvolve24(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
var
  Sum,n,s,e,w,i,x,y: Integer;
  Lin1,Lin2: PLine24;
  pc: PFColor;
begin
  Sum:=nw+ne+sw+se+m;
  if Sum=0 then Sum:=1;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      i:=(pc.b*m+Lin1[w].b*nw+Lin1[e].b*ne+Lin2[w].b*sw+Lin2[e].b*se)div Sum;
      if i>255 then pc.b:=255 else if i<0 then pc.b:=0 else pc.b:=i;
      i:=(pc.g*m+Lin1[w].g*nw+Lin1[e].g*ne+Lin2[w].g*sw+Lin2[e].g*se)div Sum;
      if i>255 then pc.g:=255 else if i<0 then pc.g:=0 else pc.g:=i;
      i:=(pc.r*m+Lin1[w].r*nw+Lin1[e].r*ne+Lin2[w].r*sw+Lin2[e].r*se)div Sum;
      if i>255 then pc.r:=255 else if i<0 then pc.r:=0 else pc.r:=i;
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure SplitConvolve32(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
var
  Sum,n,s,e,w,i,x,y: Integer;
  Lin1,Lin2: PLine32;
  pc: PFColorA;
begin
  Sum:=nw+ne+sw+se+m;
  if Sum=0 then Sum:=1;
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    n:=y+Split; if n>Bmp.AbsHeight-1 then n:=Bmp.AbsHeight-1;
    s:=y-Split; if s<0 then s:=0;
    Lin1:=Bmp.Scanlines[s];
    Lin2:=Bmp.Scanlines[n];
    for x:=0 to Bmp.Width-1 do
    begin
      e:=x+Split; if e>Bmp.Width-1 then e:=Bmp.Width-1;
      w:=x-Split; if w<0 then w:=0;
      i:=(pc.b*m+Lin1[w].b*nw+Lin1[e].b*ne+Lin2[w].b*sw+Lin2[e].b*se)div Sum;
      if i>255 then pc.b:=255 else if i<0 then pc.b:=0 else pc.b:=i;
      i:=(pc.g*m+Lin1[w].g*nw+Lin1[e].g*ne+Lin2[w].g*sw+Lin2[e].g*se)div Sum;
      if i>255 then pc.g:=255 else if i<0 then pc.g:=0 else pc.g:=i;
      i:=(pc.r*m+Lin1[w].r*nw+Lin1[e].r*ne+Lin2[w].r*sw+Lin2[e].r*se)div Sum;
      if i>255 then pc.r:=255 else if i<0 then pc.r:=0 else pc.r:=i;
      Inc(pc);
    end;
  end;
end;

procedure SplitConvolve(Bmp:TFastDIB;Split,nw,ne,sw,se,m:Integer);
begin
  case Bmp.Bpp of
    8:  SplitConvolve8(Bmp,Split,nw,ne,sw,se,m);
    16: SplitConvolve16(Bmp,Split,nw,ne,sw,se,m);
    24: SplitConvolve24(Bmp,Split,nw,ne,sw,se,m);
    32: SplitConvolve32(Bmp,Split,nw,ne,sw,se,m);
  end;
end;

procedure BlurEdges(Bmp:TFastDIB;Split:Integer);
begin
  SplitConvolve(Bmp,Split,2,2,2,2,-3);
end;

procedure BleedEdges(Bmp:TFastDIB;Split:Integer);
begin
  SplitConvolve(Bmp,Split,2,2,2,2,-4);
end;

procedure Sharpen(Bmp:TFastDIB;Split:Integer);
begin
  SplitConvolve(Bmp,Split,1,1,1,1,-10);
end;

procedure SharpenMore(Bmp:TFastDIB;Split:Integer);
begin
  SplitConvolve(Bmp,Split,5,5,5,5,-35);
end;

procedure EmbossEdges(Bmp:TFastDIB;Split:Integer);
begin
  SplitConvolve(Bmp,Split,4,4,-4,-4,10);
end;

procedure QuickSoft8(Bmp:TFastDIB);
var
  a,b,c: PByte;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+1);
  c:=Ptr(Integer(b)+1);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    a^:=(a^+b^)shr 1;
    for x:=0 to Bmp.Width-3 do
    begin
      b^:=(a^+c^)shr 1;
      Inc(a); Inc(b); Inc(c);
    end;
    b^:=(b^+a^)shr 1;
    Inc(a,Bmp.Gap+2);
    Inc(b,Bmp.Gap+2);
    Inc(c,Bmp.Gap+2);
  end;
end;

procedure QuickSoft24(Bmp:TFastDIB);
var
  a,b,c: PFColor;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+3);
  c:=Ptr(Integer(b)+3);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    a.b:=(a.b+b.b)shr 1;
    a.g:=(a.g+b.g)shr 1;
    a.r:=(a.r+b.r)shr 1;
    for x:=0 to Bmp.Width-3 do
    begin
      b.b:=(a.b+c.b)shr 1;
      b.g:=(a.g+c.g)shr 1;
      b.r:=(a.r+c.r)shr 1;
      Inc(a); Inc(b); Inc(c);
    end;
    b.b:=(b.b+a.b)shr 1;
    b.g:=(b.g+a.g)shr 1;
    b.r:=(b.r+a.r)shr 1;
    a:=Ptr(Integer(a)+Bmp.Gap+6);
    b:=Ptr(Integer(b)+Bmp.Gap+6);
    c:=Ptr(Integer(c)+Bmp.Gap+6);
  end;
end;

procedure QuickSoft32(Bmp:TFastDIB);
var
  a,b,c: PFColorA;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+4);
  c:=Ptr(Integer(b)+4);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    a.b:=(a.b+b.b)shr 1;
    a.g:=(a.g+b.g)shr 1;
    a.r:=(a.r+b.r)shr 1;
    for x:=0 to Bmp.Width-3 do
    begin
      b.b:=(a.b+c.b)shr 1;
      b.g:=(a.g+c.g)shr 1;
      b.r:=(a.r+c.r)shr 1;
      Inc(a); Inc(b); Inc(c);
    end;
    b.b:=(b.b+a.b)shr 1;
    b.g:=(b.g+a.g)shr 1;
    b.r:=(b.r+a.r)shr 1;
    a:=Ptr(Integer(a)+Bmp.Gap+8);
    b:=Ptr(Integer(b)+Bmp.Gap+8);
    c:=Ptr(Integer(c)+Bmp.Gap+8);
  end;
end;

procedure QuickSoft(Bmp:TFastDIB);
begin
  case Bmp.Bpp of
    8:  QuickSoft8(Bmp);
    24: QuickSoft24(Bmp);
    32: QuickSoft32(Bmp);
  end;
end;

procedure QuickSharp8(Bmp:TFastDIB);
var
  a,b,c: PByte;
  x,y,i: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+1);
  c:=Ptr(Integer(b)+1);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    i:=((a^ shl 2)-(a^+b^))div 2;
    if i>255 then a^:=255 else if i<0 then a^:=0 else a^:=i;
    for x:=0 to Bmp.Width-3 do
    begin
      i:=((b^ shl 2)-(a^+c^))div 2;
      if i>255 then b^:=255 else if i<0 then b^:=0 else b^:=i;
      Inc(a); Inc(b); Inc(c);
    end;
    i:=((b^ shl 2)-(b^+a^))div 2;
    if i>255 then b^:=255 else if i<0 then b^:=0 else b^:=i;
    Inc(a,Bmp.Gap+2);
    Inc(b,Bmp.Gap+2);
    Inc(c,Bmp.Gap+2);
  end;
end;

procedure QuickSharp24(Bmp:TFastDIB);
var
  a,b,c: PFColor;
  x,y,i: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+3);
  c:=Ptr(Integer(b)+3);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    i:=((a.b shl 2)-(a.b+b.b))div 2;
    if i>255 then a.b:=255 else if i<0 then a.b:=0 else a.b:=i;
    i:=((a.g shl 2)-(a.g+b.g))div 2;
    if i>255 then a.g:=255 else if i<0 then a.g:=0 else a.g:=i;
    i:=((a.r shl 2)-(a.r+b.r))div 2;
    if i>255 then a.r:=255 else if i<0 then a.r:=0 else a.r:=i;
    for x:=0 to Bmp.Width-3 do
    begin
      i:=((b.b shl 2)-(a.b+c.b))div 2;
      if i>255 then b.b:=255 else if i<0 then b.b:=0 else b.b:=i;
      i:=((b.g shl 2)-(a.g+c.g))div 2;
      if i>255 then b.g:=255 else if i<0 then b.g:=0 else b.g:=i;
      i:=((b.r shl 2)-(a.r+c.r))div 2;
      if i>255 then b.r:=255 else if i<0 then b.r:=0 else b.r:=i;
      Inc(a); Inc(b); Inc(c);
    end;
    i:=((b.b shl 2)-(b.b+a.b))div 2;
    if i>255 then b.b:=255 else if i<0 then b.b:=0 else b.b:=i;
    i:=((b.g shl 2)-(b.g+a.g))div 2;
    if i>255 then b.g:=255 else if i<0 then b.g:=0 else b.g:=i;
    i:=((b.r shl 2)-(b.r+a.r))div 2;
    if i>255 then b.r:=255 else if i<0 then b.r:=0 else b.r:=i;
    a:=Ptr(Integer(a)+Bmp.Gap+6);
    b:=Ptr(Integer(b)+Bmp.Gap+6);
    c:=Ptr(Integer(c)+Bmp.Gap+6);
  end;
end;

procedure QuickSharp32(Bmp:TFastDIB);
var
  a,b,c: PFColorA;
  x,y,i: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+4);
  c:=Ptr(Integer(b)+4);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    i:=((a.b shl 2)-(a.b+b.b))div 2;
    if i>255 then a.b:=255 else if i<0 then a.b:=0 else a.b:=i;
    i:=((a.g shl 2)-(a.g+b.g))div 2;
    if i>255 then a.g:=255 else if i<0 then a.g:=0 else a.g:=i;
    i:=((a.r shl 2)-(a.r+b.r))div 2;
    if i>255 then a.r:=255 else if i<0 then a.r:=0 else a.r:=i;
    for x:=0 to Bmp.Width-3 do
    begin
      i:=((b.b shl 2)-(a.b+c.b))div 2;
      if i>255 then b.b:=255 else if i<0 then b.b:=0 else b.b:=i;
      i:=((b.g shl 2)-(a.g+c.g))div 2;
      if i>255 then b.g:=255 else if i<0 then b.g:=0 else b.g:=i;
      i:=((b.r shl 2)-(a.r+c.r))div 2;
      if i>255 then b.r:=255 else if i<0 then b.r:=0 else b.r:=i;
      Inc(a); Inc(b); Inc(c);
    end;
    i:=((b.b shl 2)-(b.b+a.b))div 2;
    if i>255 then b.b:=255 else if i<0 then b.b:=0 else b.b:=i;
    i:=((b.g shl 2)-(b.g+a.g))div 2;
    if i>255 then b.g:=255 else if i<0 then b.g:=0 else b.g:=i;
    i:=((b.r shl 2)-(b.r+a.r))div 2;
    if i>255 then b.r:=255 else if i<0 then b.r:=0 else b.r:=i;
    a:=Ptr(Integer(a)+Bmp.Gap+8);
    b:=Ptr(Integer(b)+Bmp.Gap+8);
    c:=Ptr(Integer(c)+Bmp.Gap+8);
  end;
end;

procedure QuickSharp(Bmp:TFastDIB);
begin
  case Bmp.Bpp of
    8:  QuickSharp8(Bmp);
    24: QuickSharp24(Bmp);
    32: QuickSharp32(Bmp);
  end;
end;

procedure QuickEmboss8(Bmp:TFastDIB);
var
  a,b: PByte;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+1);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-2 do
    begin
      a^:=(b^+(a^ xor Integer(-1))and $FF)shr 1;
      Inc(a); Inc(b);
    end;
    a^:=(a^+(a^ xor Integer(-1))and $FF)shr 1;
    Inc(a,Bmp.Gap+1);
    Inc(b,Bmp.Gap+1);
  end;
end;

procedure QuickEmboss24(Bmp:TFastDIB);
var
  a,b: PFColor;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+3);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-2 do
    begin
      a.b:=(b.b+(a.b xor $FFFFFFFF)and $FF)shr 1;
      a.g:=(b.g+(a.g xor $FFFFFFFF)and $FF)shr 1;
      a.r:=(b.r+(a.r xor $FFFFFFFF)and $FF)shr 1;
      Inc(a); Inc(b);
    end;
    a.b:=(a.b+(a.b xor $FFFFFFFF)and $FF)shr 1;
    a.g:=(a.g+(a.g xor $FFFFFFFF)and $FF)shr 1;
    a.r:=(a.r+(a.r xor $FFFFFFFF)and $FF)shr 1;
    a:=Ptr(Integer(a)+Bmp.Gap+3);
    b:=Ptr(Integer(b)+Bmp.Gap+3);
  end;
end;

procedure QuickEmboss32(Bmp:TFastDIB);
var
  a,b: PFColorA;
  x,y: Integer;
begin
  a:=Pointer(Bmp.Bits);
  b:=Ptr(Integer(a)+4);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to Bmp.Width-2 do
    begin
      a.b:=(b.b+(a.b xor $FFFFFFFF)and $FF)shr 1;
      a.g:=(b.g+(a.g xor $FFFFFFFF)and $FF)shr 1;
      a.r:=(b.r+(a.r xor $FFFFFFFF)and $FF)shr 1;
      Inc(a); Inc(b);
    end;
    a.b:=(a.b+(a.b xor $FFFFFFFF)and $FF)shr 1;
    a.g:=(a.g+(a.g xor $FFFFFFFF)and $FF)shr 1;
    a.r:=(a.r+(a.r xor $FFFFFFFF)and $FF)shr 1;
    a:=Ptr(Integer(a)+Bmp.Gap+4);
    b:=Ptr(Integer(b)+Bmp.Gap+4);
  end;
end;

procedure QuickEmboss(Bmp:TFastDIB);
begin
  case Bmp.Bpp of
    8:  QuickEmboss8(Bmp);
    24: QuickEmboss24(Bmp);
    32: QuickEmboss32(Bmp);
  end;
end;

procedure Lines8(Bmp:TFastDIB;Lut:TLut);
var
  x,y: Integer;
  pb: PByte;
begin
  pb:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    if(y and 1)=0 then
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        pb^:=Lut[pb^];
        Inc(pb);
      end;
    end else Inc(pb,Bmp.BWidth-Bmp.Gap);
    Inc(pb,Bmp.Gap);
  end;
end;

procedure Lines16(Bmp:TFastDIB;Lut:TWLut);
var
  x,y: Integer;
  pw:  PWord;
begin
  pw:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    if(y and 1)=0 then
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        pw^:=Lut[pw^];
        Inc(pw);
      end;
    end else pw:=Ptr(Integer(pw)+Bmp.BWidth-Bmp.Gap);
    pw:=Ptr(Integer(pw)+Bmp.Gap);
  end;
end;

procedure Lines24(Bmp:TFastDIB;Lut:TLut);
var
  x,y: Integer;
  pc: PFColor;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    if(y and 1)=0 then
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        pc.b:=Lut[pc.b];
        pc.g:=Lut[pc.g];
        pc.r:=Lut[pc.r];
        Inc(pc);
      end;
    end else pc:=Ptr(Integer(pc)+Bmp.BWidth-Bmp.Gap);
    pc:=Ptr(Integer(pc)+Bmp.Gap);
  end;
end;

procedure Lines32(Bmp:TFastDIB;Lut:TLut);
var
  x,y: Integer;
  pc: PFColorA;
begin
  pc:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    if(y and 1)=0 then
    begin
      for x:=0 to Bmp.Width-1 do
      begin
        pc.b:=Lut[pc.b];
        pc.g:=Lut[pc.g];
        pc.r:=Lut[pc.r];
        Inc(pc);
      end;
    end else pc:=Ptr(Integer(pc)+Bmp.BWidth);
  end;
end;

procedure Lines(Bmp:TFastDIB;Lut:TLut);
begin
  case Bmp.Bpp of
    8:  Lines8(Bmp,Lut);
    16: Lines16(Bmp,MakeWLut(Bmp,Lut,Lut,Lut));
    24: Lines24(Bmp,Lut);
    32: Lines32(Bmp,Lut);
  end;
end;

procedure Mosaic8(Bmp:TFastDIB;xAmount,yAmount:Integer);
var
  Delta,tx,ty,ix,iy,cx,cy,x,y: Integer;
  Line: PLine8;
  pc: PByte;
  tc: Byte;
begin
  xAmount:=Abs(xAmount);
  yAmount:=Abs(yAmount);
  if(xAmount=0)or(yAmount=0)then Exit;
  ix:=(xAmount shr 1)+(xAmount and 1);
  iy:=(yAmount shr 1)+(yAmount and 1);
  y:=0;
  while y<Bmp.AbsHeight do
  begin
    x:=0;
    cy:=y+iy;
    if cy>=Bmp.AbsHeight then Line:=Bmp.Scanlines[Bmp.AbsHeight-1]else Line:=Bmp.Scanlines[cy];
    if y+yAmount-1>Bmp.AbsHeight-1 then ty:=Bmp.AbsHeight-y else ty:=yAmount;
    while x<Bmp.Width do
    begin
      cx:=x+ix;
      if cx>=Bmp.Width then tc:=Line[Bmp.Width-1]else tc:=Line[cx];
      if x+xAmount-1>Bmp.Width-1 then tx:=Bmp.Width-x else tx:=xAmount;
      Delta:=Integer(Bmp.BWidth)-tx;
      pc:=@Bmp.Pixels8[y,x];
      for cy:=1 to ty do
      begin
        for cx:=1 to tx do
        begin
          pc^:=tc;
          Inc(pc);
        end;
        Inc(pc,Delta);
      end;
      Inc(x,xAmount);
    end;
    Inc(y,yAmount);
  end;
end;

procedure Mosaic16(Bmp:TFastDIB;xAmount,yAmount:Integer);
var
  Delta,tx,ty,ix,iy,cx,cy,x,y: Integer;
  Line: PLine16;
  pc: PWord;
  tc: Word;
begin
  xAmount:=Abs(xAmount);
  yAmount:=Abs(yAmount);
  if(xAmount=0)or(yAmount=0)then Exit;
  ix:=(xAmount shr 1)+(xAmount and 1);
  iy:=(yAmount shr 1)+(yAmount and 1);
  y:=0;
  while y<Bmp.AbsHeight do
  begin
    x:=0; cy:=y+iy;
    if cy>=Bmp.AbsHeight then Line:=Bmp.Scanlines[Bmp.AbsHeight-1]else Line:=Bmp.Scanlines[cy];
    if y+yAmount-1>Bmp.AbsHeight-1 then ty:=Bmp.AbsHeight-y else ty:=yAmount;
    while x<Bmp.Width do
    begin
      cx:=x+ix;
      if cx>=Bmp.Width then tc:=Line[Bmp.Width-1]else tc:=Line[cx];
      if x+xAmount-1>Bmp.Width-1 then tx:=Bmp.Width-x else tx:=xAmount;
      Delta:=Integer(Bmp.BWidth)-tx*2; pc:=@Bmp.Pixels16[y,x];
      for cy:=1 to ty do
      begin
        for cx:=1 to tx do
        begin
          pc^:=tc;
          Inc(pc);
        end;
        pc:=Ptr(Integer(pc)+Delta);
      end;
      Inc(x,xAmount);
    end;
    Inc(y,yAmount);
  end;
end;

procedure Mosaic24(Bmp:TFastDIB;xAmount,yAmount:Integer);
var
  Delta,tx,ty,ix,iy,cx,cy,x,y: Integer;
  Line: PLine24;
  pc: PFColor;
  tc: TFColor;
begin
  xAmount:=Abs(xAmount);
  yAmount:=Abs(yAmount);
  if(xAmount=0)or(yAmount=0)then Exit;
  ix:=(xAmount shr 1)+(xAmount and 1);
  iy:=(yAmount shr 1)+(yAmount and 1);
  y:=0;
  while y<Bmp.AbsHeight do
  begin
    x:=0; cy:=y+iy;
    if cy>=Bmp.AbsHeight then Line:=Bmp.Scanlines[Bmp.AbsHeight-1]else Line:=Bmp.Scanlines[cy];
    if y+yAmount-1>Bmp.AbsHeight-1 then ty:=Bmp.AbsHeight-y else ty:=yAmount;
    while x<Bmp.Width do
    begin
      cx:=x+ix;
      if cx>=Bmp.Width then tc:=Line[Bmp.Width-1]else tc:=Line[cx];
      if x+xAmount-1>Bmp.Width-1 then tx:=Bmp.Width-x else tx:=xAmount;
      Delta:=Integer(Bmp.BWidth)-tx*3;
      pc:=@Bmp.Pixels24[y,x];
      for cy:=1 to ty do
      begin
        for cx:=1 to tx do
        begin
          pc^:=tc;
          Inc(pc);
        end;
        pc:=Ptr(Integer(pc)+Delta);
      end;
      Inc(x,xAmount);
    end;
    Inc(y,yAmount);
  end;
end;

procedure Mosaic32(Bmp:TFastDIB;xAmount,yAmount:Integer);
var
  Delta,tx,ty,ix,iy,cx,cy,x,y: Integer;
  Line: PLine32;
  pc: PFColorA;
  tc: TFColorA;
begin
  xAmount:=Abs(xAmount);
  yAmount:=Abs(yAmount);
  if(xAmount=0)or(yAmount=0)then Exit;
  ix:=(xAmount shr 1)+(xAmount and 1);
  iy:=(yAmount shr 1)+(yAmount and 1);
  y:=0;
  while y<Bmp.AbsHeight do
  begin
    x:=0; cy:=y+iy;
    if cy>=Bmp.AbsHeight then Line:=Bmp.Scanlines[Bmp.AbsHeight-1]else Line:=Bmp.Scanlines[cy];
    if y+yAmount-1>Bmp.AbsHeight-1 then ty:=Bmp.AbsHeight-y else ty:=yAmount;
    while x<Bmp.Width do
    begin
      cx:=x+ix;
      if cx>=Bmp.Width then tc:=Line[Bmp.Width-1]else tc:=Line[cx];
      if x+xAmount-1>Bmp.Width-1 then tx:=Bmp.Width-x else tx:=xAmount;
      Delta:=Integer(Bmp.BWidth)-tx*4;
      pc:=@Bmp.Pixels32[y,x];
      for cy:=1 to ty do
      begin
        for cx:=1 to tx do
        begin
          pc^:=tc;
          Inc(pc);
        end;
        pc:=Ptr(Integer(pc)+Delta);
      end;
      Inc(x,xAmount);
    end;
    Inc(y,yAmount);
  end;
end;

procedure Mosaic(Bmp:TFastDIB;xAmount,yAmount:Integer);
begin
  case Bmp.Bpp of
    8:  Mosaic8(Bmp,xAmount,yAmount);
    16: Mosaic16(Bmp,xAmount,yAmount);
    24: Mosaic24(Bmp,xAmount,yAmount);
    32: Mosaic32(Bmp,xAmount,yAmount);
  end;
end;

procedure Shift(Bmp:TFastDIB;xAmount,yAmount:Integer);
var
  y,Size: Integer;
  Line,Buf: PLine8;
begin
  if yAmount<>0 then
  begin
    if yAmount<0 then yAmount:=Bmp.AbsHeight-(-yAmount mod Bmp.AbsHeight);
    if yAmount>Bmp.AbsHeight then yAmount:=yAmount mod Bmp.AbsHeight;
    if Bmp.Size<>0 then
    begin
      Size:=yAmount*Bmp.BWidth;
      GetMem(Buf,Size);
      Move(Bmp.Bits^,Buf^,Size);
      Move(Bmp.Scanlines[yAmount]^,Bmp.Bits^,(Bmp.AbsHeight-yAmount)*Bmp.BWidth);
      Move(Buf^,Bmp.Scanlines[Bmp.AbsHeight-yAmount]^,Size);
      FreeMem(Buf);
    end else
    begin
      Size:=Bmp.BWidth-Bmp.Gap;
      GetMem(Buf,yAmount*Size);
      Line:=Pointer(Buf);
      for y:=0 to yAmount-1 do
      begin
        Move(Bmp.Scanlines[y]^,Line^,Size);
        Line:=Ptr(Integer(Line)+Size);
      end;
      for y:=yAmount to Bmp.AbsHeight-1 do
        Move(Bmp.Scanlines[y]^,Bmp.Scanlines[Integer(y)-yAmount]^,Size);
      Line:=Pointer(Buf);
      for y:=Bmp.AbsHeight-yAmount to Bmp.AbsHeight-1 do
      begin
        Move(Line^,Bmp.Scanlines[y]^,Size);
        Line:=Ptr(Integer(Line)+Size);
      end;
      FreeMem(Buf);
    end;
  end;
  if xAmount<>0 then
  begin
    if xAmount<0 then xAmount:=Bmp.Width-(-xAmount mod Bmp.Width);
    if xAmount>Bmp.Width then xAmount:=xAmount mod Bmp.Width;
    Size:=xAmount*(Bmp.Bpp div 8);
    GetMem(Buf,Size);
    Line:=Bmp.Bits;
    for y:=0 to Bmp.AbsHeight-1 do
    begin
      Move(Line^,Buf^,Size);
      Move(Ptr(Integer(Line)+Size)^,Line^,(Bmp.BWidth-Bmp.Gap)-Size);
      Move(Buf^,Ptr(Integer(Line)+((Bmp.BWidth-Bmp.Gap)-Size))^,Size);
      Line:=Ptr(Integer(Line)+Bmp.BWidth);
    end;
    FreeMem(Buf);
  end;
end;

procedure AvgFrames8(Dst:TFastDIB;Src:array of TFastDIB;Count:Integer);
var
  Lut: TLut;
  i,x,y: Integer;
  pb,pc: PByte;
begin
  FillLut(Lut,0,0,255,255 div Count);
  ClearB(Dst,0);
  for i:=0 to Count-1 do
  begin
    pb:=Pointer(Dst.Bits);
    pc:=Pointer(Src[i].Bits);
    for y:=0 to Dst.AbsHeight-1 do
    begin
      for x:=0 to Dst.BWidth-Dst.Gap-1 do
      begin
        Inc(pb^,Lut[pc^]);
        Inc(pb);
        Inc(pc);
      end;
      Inc(pb,Dst.Gap);
      Inc(pc,Src[i].Gap);
    end;
  end;
end;

procedure AvgFrames16(Dst:TFastDIB;Src:array of TFastDIB;Count:Integer);
var
  Lut: TLut;
  i,x,y: Integer;
  pb,pc: PWord;
  ds,sr: TFColor;
  ic,id: array[Word]of TFColor;
  rw,gw,bw: array[Byte]of Word;
begin
  FillLut(Lut,0,0,255,255 div Count);
  ClearB(Dst,0);
  for i:=0 to 255 do
  begin
    bw[i]:=i shr Dst.BShr;
    gw[i]:=i shr Dst.GShr shl Dst.GShl;
    rw[i]:=i shr Dst.RShr shl Dst.RShl;
  end;
  for i:=0 to 65535 do
  begin
    id[i].b:=Scale8(i and Dst.BMask,Dst.Bpb);
    id[i].g:=Scale8(i and Dst.GMask shr Dst.GShl,Dst.Bpg);
    id[i].r:=Scale8(i and Dst.RMask shr Dst.RShl,Dst.Bpr);
  end;
  for i:=0 to Count-1 do
  begin
    for x:=0 to 65535 do
    begin
      ic[x].b:=Scale8(x and Src[i].BMask,Src[i].Bpb);
      ic[x].g:=Scale8(x and Src[i].GMask shr Src[i].GShl,Src[i].Bpg);
      ic[x].r:=Scale8(x and Src[i].RMask shr Src[i].RShl,Src[i].Bpr);
    end;
    pb:=Pointer(Dst.Bits);
    pc:=Pointer(Src[i].Bits);
    for y:=0 to Dst.AbsHeight-1 do
    begin
      for x:=0 to Dst.Width-1 do
      begin
        sr:=ic[pc^];
        ds:=id[pb^];
        pb^:=
          bw[ ds.b + Lut[ sr.b ]]or
          gw[ ds.g + Lut[ sr.g ]]or
          rw[ ds.r + Lut[ sr.r ]];
        Inc(pb);
        Inc(pc);
      end;
      pb:=Ptr(Integer(pb)+Dst.Gap);
      pc:=Ptr(Integer(pc)+Src[i].Gap);
    end;
  end;
end;

procedure AvgFrames(Dst:TFastDIB;Src:array of TFastDIB;Count:Integer);
begin
  case Dst.Bpp of
    8,24,32: AvgFrames8(Dst,Src,Count);
    16: AvgFrames16(Dst,Src,Count);
  end;
end;

procedure Flip1(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine8;
  Tmp: Byte;
  Inv: TLut;
begin
  for x:=0 to 255 do Inv[x]:=
    ((x and 128)shr 7)or
    ((x and  64)shr 5)or
    ((x and  32)shr 3)or
    ((x and  16)shr 1)or
    ((x and   8)shl 1)or
    ((x and   4)shl 3)or
    ((x and   2)shl 5)or
    ((x and   1)shl 7);
  w:=(Bmp.Width shr 3)-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Inv[Line[x]];
      Line[x]:=Inv[Line[w-x]];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip4(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine8;
  Tmp: Byte;
  Inv: TLut;
begin
  for x:=0 to 255 do Inv[x]:=(x shr 4)or(x shl 4);
  w:=(Bmp.Width shr 1)-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Inv[Line[x]];
      Line[x]:=Inv[Line[w-x]];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip8(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine8;
  Tmp: Byte;
begin
  w:=Bmp.Width-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Line[x];
      Line[x]:=Line[w-x];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip16(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine16;
  Tmp: Word;
begin
  w:=Bmp.Width-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Line[x];
      Line[x]:=Line[w-x];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip24(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine24;
  Tmp: TFColor;
begin
  w:=Bmp.Width-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Line[x];
      Line[x]:=Line[w-x];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip32(Bmp:TFastDIB);
var
  x,y,w: Integer;
  Line: PLine32;
  Tmp: TFColorA;
begin
  w:=Bmp.Width-1;
  Line:=Pointer(Bmp.Bits);
  for y:=0 to Bmp.AbsHeight-1 do
  begin
    for x:=0 to(w shr 1)do
    begin
      Tmp:=Line[x];
      Line[x]:=Line[w-x];
      Line[w-x]:=Tmp;
    end;
    Line:=Ptr(Integer(Line)+Bmp.BWidth);
  end;
end;

procedure Flip(Bmp:TFastDIB);
begin
  case Bmp.Bpp of
    1:  Flip1(Bmp);
    4:  Flip4(Bmp);
    8:  Flip8(Bmp);
    16: Flip16(Bmp);
    24: Flip24(Bmp);
    32: Flip32(Bmp);
  end;
end;

procedure Flop(Bmp:TFastDIB);
var
  h,i,len: Integer;
  p1,p2: Pointer;
  Buff: PLine8;
begin
  len:=Bmp.BWidth-Bmp.Gap;
  GetMem(Buff,len);
  h:=(Bmp.AbsHeight-1)div 2;
  p1:=Bmp.Bits; p2:=Bmp.Scanlines[Bmp.AbsHeight-1];
  for i:=0 to h do
  begin
    Move(p1^,Buff^,len);
    Move(p2^,p1^,len);
    Move(Buff^,p2^,len);
    p1:=Ptr(Integer(p1)+Bmp.BWidth);
    p2:=Ptr(Integer(p2)-Bmp.BWidth);
  end;
  FreeMem(Buff);
end;

procedure Rotate90CW(Src,Dst:TFastDIB);
var
  sInfo: TBMInfo;
begin
  sInfo:=Src.Info;
  sInfo.Header.Width:=Src.Height;
  sInfo.Header.Height:=Src.Width;
  Dst.SetSizeIndirect(sInfo);
  Transform(Src,Dst,Dst.Width shr 1,Dst.Height shr 1,65536,0,False);
end;

procedure Rotate90CCW(Src,Dst:TFastDIB);
var
  sInfo: TBMInfo;
begin
  sInfo:=Src.Info;
  sInfo.Header.Width:=Src.Height;
  sInfo.Header.Height:=Src.Width;
  Dst.SetSizeIndirect(sInfo);
  Transform(Src,Dst,Dst.Width shr 1,Dst.Height shr 1,-65536,0,False);
end;

procedure Rotate180(Src,Dst:TFastDIB);
begin
  Dst.SetSizeIndirect(Src.Info);
  Transform(Src,Dst,Dst.Width shr 1,Dst.Height shr 1,0,-65536,False);
end;

procedure RotateSize(Src,Dst:TFastDIB;Angle:Double);
var
  sInfo: TBMInfo;
  Theta: Double;
begin
  Theta:=Abs(Angle)*(Pi/180);
  sInfo:=Src.Info;
  sInfo.Header.Width:=Round(Abs(Src.Width*Cos(Theta))+Abs(Src.Height*Sin(Theta))+0.4);
  sInfo.Header.Height:=Round(Abs(Src.Width*Sin(Theta))+Abs(Src.Height*Cos(Theta))+0.4);
  Dst.SetSizeIndirect(sInfo);
  Transform(Src,Dst,
    Dst.Width shr 1,
    Dst.Height shr 1,
    Round(Sin(Angle*Pi/180)*65536),
    Round(Cos(Angle*Pi/180)*65536),
    True);  
end;

procedure Transform8(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
var
  x,y,t1,t2,dx,dy,xd,yd,sdx,sdy,ax,ay,ex,ey: Integer;
  c00,c01,c10,c11: Byte;
  pc,sp: PByte;
begin
  c00:=0; c01:=0; c10:=0; c11:=0; //shutup!

  xd:=((Src.Width shl 16)-(Dst.Width shl 16))div 2;
  yd:=((Src.Height shl 16)-(Dst.Height shl 16))div 2;
  ax:=(cx shl 16)-(icos*cx);
  ay:=(cy shl 16)-(isin*cx);
  pc:=Pointer(Dst.Bits);
  if Smooth then
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=Smallint(sdx shr 16);
        dy:=Smallint(sdy shr 16);
        if(dx>=-1)and(dy>=-1)and(dx<Src.Width)and(dy<Src.Height)then
        begin
          if(dx>=0)and(dy>=0)and(dx<Src.Width-1)and(dy<Src.Height-1)then
          begin
            sp:=@Src.Pixels8[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^; Inc(sp,Src.BWidth-1);
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if(dx=Src.Width-1)and(dy=Src.Height-1)then
          begin
            c00:=Src.Pixels8[dy,dx];
            c01:=pc^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=pc^;
            c11:=PByte(Src.Bits)^;
          end else if(dx=-1)and(dy=Src.Height-1)then
          begin
            c00:=pc^;
            c01:=PByte(Src.Scanlines[dy])^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=Src.Width-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=Src.Pixels8[0,dx];;
            c11:=pc^;
          end else if dx=-1 then
          begin
            c00:=pc^; sp:=@Src.Pixels8[dy,0];
            c01:=sp^;
            c10:=pc^; Inc(sp,Src.BWidth);
            c11:=sp^;
          end else if dy=-1 then
          begin
            c00:=pc^;
            c01:=pc^; sp:=@Src.Pixels8[0,dx];
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if dx=Src.Width-1 then
          begin
            sp:=@Src.Pixels8[dy,dx];
            c00:=sp^;
            c01:=pc^; Inc(sp,Src.BWidth);
            c10:=sp^;
            c11:=pc^;
          end else if dy=Src.Height-1 then
          begin
            sp:=@Src.Pixels8[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^;
            c10:=pc^;
            c11:=pc^;
          end;
          ex:=sdx and $FFFF;
          ey:=sdy and $FFFF;
          t1:=((((c01-c00)*ex)shr 16)+c00)and $FF;
          t2:=((((c11-c10)*ex)shr 16)+c10)and $FF;
          pc^:=(((t2-t1)*ey)shr 16)+t1;
        end;
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      Inc(pc,Dst.Gap);
    end;
  end else
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=sdx shr 16;
        dy:=sdy shr 16;
        if(dx<Src.Width)and(dy<Src.Height)then pc^:=Src.Pixels8[dy,dx];
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      Inc(pc,Dst.Gap);
    end;
  end;
end;

procedure Transform16(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
var
  x,y,t1,t2,dx,dy,xd,yd,sdx,sdy,ax,ay,ex,ey: Integer;
  c00,c01,c10,c11: Word;
  ri,gi,bi: array[Word]of Byte;
  rw,gw,bw: array[Byte]of Word;
  pc,sp: PWord;
  r,g,b: Word;
begin
  c00:=0; c01:=0; c10:=0; c11:=0; //shutup!

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
  xd:=((Src.Width shl 16)-(Dst.Width shl 16))div 2;
  yd:=((Src.Height shl 16)-(Dst.Height shl 16))div 2;
  ax:=(cx shl 16)-(icos*cx);
  ay:=(cy shl 16)-(isin*cx);
  pc:=Pointer(Dst.Bits);
  if Smooth then
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=Smallint(sdx shr 16);
        dy:=Smallint(sdy shr 16);
        if(dx>=-1)and(dy>=-1)and(dx<Src.Width)and(dy<Src.Height)then
        begin
          if(dx>=0)and(dy>=0)and(dx<Src.Width-1)and(dy<Src.Height-1)then
          begin
            sp:=@Src.Pixels16[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^; sp:=Ptr(Integer(sp)+Src.BWidth-2);
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if(dx=Src.Width-1)and(dy=Src.Height-1)then
          begin
            c00:=Src.Pixels16[dy,dx];
            c01:=pc^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=pc^;
            c11:=PWord(Src.Bits)^;
          end else if(dx=-1)and(dy=Src.Height-1)then
          begin
            c00:=pc^;
            c01:=PWord(Src.Scanlines[dy])^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=Src.Width-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=Src.Pixels16[0,dx];;
            c11:=pc^;
          end else if dx=-1 then
          begin
            c00:=pc^; sp:=@Src.Pixels16[dy,0];
            c01:=sp^;
            c10:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c11:=sp^;
          end else if dy=-1 then
          begin
            c00:=pc^;
            c01:=pc^; sp:=@Src.Pixels16[0,dx];
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if dx=Src.Width-1 then
          begin
            sp:=@Src.Pixels16[dy,dx];
            c00:=sp^;
            c01:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c10:=sp^;
            c11:=pc^;
          end else if dy=Src.Height-1 then
          begin
            sp:=@Src.Pixels16[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^;
            c10:=pc^;
            c11:=pc^;
          end;
          ex:=sdx and $FFFF;
          ey:=sdy and $FFFF;
          t1:=((((bi[c01]-bi[c00])*ex)shr 16)+bi[c00])and $FF;
          t2:=((((bi[c11]-bi[c10])*ex)shr 16)+bi[c10])and $FF;
          b:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((gi[c01]-gi[c00])*ex)shr 16)+gi[c00])and $FF;
          t2:=((((gi[c11]-gi[c10])*ex)shr 16)+gi[c10])and $FF;
          g:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((ri[c01]-ri[c00])*ex)shr 16)+ri[c00])and $FF;
          t2:=((((ri[c11]-ri[c10])*ex)shr 16)+ri[c10])and $FF;
          r:=(((t2-t1)*ey)shr 16)+t1;
          pc^:=bw[b] or gw[g] or rw[r];
        end;
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end;
  end else
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=sdx shr 16;
        dy:=sdy shr 16;
        if(dx<Src.Width)and(dy<Src.Height)then pc^:=Src.Pixels16[dy,dx];
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end;
  end;
end;

procedure Transform24(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
var
  x,y,t1,t2,dx,dy,xd,yd,sdx,sdy,ax,ay,ex,ey: Integer;
  c00,c01,c10,c11: TFColor;
  pc,sp: PFColor;
begin
  xd:=((Src.Width shl 16)-(Dst.Width shl 16))div 2;
  yd:=((Src.Height shl 16)-(Dst.Height shl 16))div 2;
  ax:=(cx shl 16)-(icos*cx);
  ay:=(cy shl 16)-(isin*cx);
  pc:=Pointer(Dst.Bits);
  if Smooth then
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=Smallint(sdx shr 16);
        dy:=Smallint(sdy shr 16);
        if(dx>=-1)and(dy>=-1)and(dx<Src.Width)and(dy<Src.Height)then
        begin
          if(dx>=0)and(dy>=0)and(dx<Src.Width-1)and(dy<Src.Height-1)then
          begin
            sp:=@Src.Pixels24[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^; sp:=Ptr(Integer(sp)+Src.BWidth-3);
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if(dx=Src.Width-1)and(dy=Src.Height-1)then
          begin
            c00:=Src.Pixels24[dy,dx];
            c01:=pc^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=pc^;
            c11:=PFColor(Src.Bits)^;
          end else if(dx=-1)and(dy=Src.Height-1)then
          begin
            c00:=pc^;
            c01:=PFColor(Src.Scanlines[dy])^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=Src.Width-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=Src.Pixels24[0,dx];;
            c11:=pc^;
          end else if dx=-1 then
          begin
            c00:=pc^; sp:=@Src.Pixels24[dy,0];
            c01:=sp^;
            c10:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c11:=sp^;
          end else if dy=-1 then
          begin
            c00:=pc^;
            c01:=pc^; sp:=@Src.Pixels24[0,dx];
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if dx=Src.Width-1 then
          begin
            sp:=@Src.Pixels24[dy,dx];
            c00:=sp^;
            c01:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c10:=sp^;
            c11:=pc^;
          end else if dy=Src.Height-1 then
          begin
            sp:=@Src.Pixels24[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^;
            c10:=pc^;
            c11:=pc^;
          end;
          ex:=sdx and $FFFF;
          ey:=sdy and $FFFF;
          t1:=((((c01.b-c00.b)*ex)shr 16)+c00.b)and $FF;
          t2:=((((c11.b-c10.b)*ex)shr 16)+c10.b)and $FF;
          pc.b:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((c01.g-c00.g)*ex)shr 16)+c00.g)and $FF;
          t2:=((((c11.g-c10.g)*ex)shr 16)+c10.g)and $FF;
          pc.g:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((c01.r-c00.r)*ex)shr 16)+c00.r)and $FF;
          t2:=((((c11.r-c10.r)*ex)shr 16)+c10.r)and $FF;
          pc.r:=(((t2-t1)*ey)shr 16)+t1;
        end;
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end;
  end else
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=sdx shr 16;
        dy:=sdy shr 16;
        if(dx<Src.Width)and(dy<Src.Height)then pc^:=Src.Pixels24[dy,dx];
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end;
  end;
end;

procedure Transform32(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
var
  x,y,t1,t2,dx,dy,xd,yd,sdx,sdy,ax,ay,ex,ey: Integer;
  c00,c01,c10,c11: TFColorA;
  pc,sp: PFColorA;
begin
  xd:=((Src.Width shl 16)-(Dst.Width shl 16))div 2;
  yd:=((Src.Height shl 16)-(Dst.Height shl 16))div 2;
  ax:=(cx shl 16)-(icos*cx);
  ay:=(cy shl 16)-(isin*cx);
  pc:=Pointer(Dst.Bits);
  if Smooth then
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=Smallint(sdx shr 16);
        dy:=Smallint(sdy shr 16);
        if(dx>=-1)and(dy>=-1)and(dx<Src.Width)and(dy<Src.Height)then
        begin
          if(dx>=0)and(dy>=0)and(dx<Src.Width-1)and(dy<Src.Height-1)then
          begin
            sp:=@Src.Pixels32[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^; sp:=Ptr(Integer(sp)+Src.BWidth-4);
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if(dx=Src.Width-1)and(dy=Src.Height-1)then
          begin
            c00:=Src.Pixels32[dy,dx];
            c01:=pc^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=pc^;
            c11:=PFColorA(Src.Bits)^;
          end else if(dx=-1)and(dy=Src.Height-1)then
          begin
            c00:=pc^;
            c01:=PFColorA(Src.Scanlines[dy])^;
            c10:=pc^;
            c11:=pc^;
          end else if(dx=Src.Width-1)and(dy=-1)then
          begin
            c00:=pc^;
            c01:=pc^;
            c10:=Src.Pixels32[0,dx];;
            c11:=pc^;
          end else if dx=-1 then
          begin
            c00:=pc^; sp:=@Src.Pixels32[dy,0];
            c01:=sp^;
            c10:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c11:=sp^;
          end else if dy=-1 then
          begin
            c00:=pc^;
            c01:=pc^; sp:=@Src.Pixels32[0,dx];
            c10:=sp^; Inc(sp);
            c11:=sp^;
          end else if dx=Src.Width-1 then
          begin
            sp:=@Src.Pixels32[dy,dx];
            c00:=sp^;
            c01:=pc^; sp:=Ptr(Integer(sp)+Src.BWidth);
            c10:=sp^;
            c11:=pc^;
          end else if dy=Src.Height-1 then
          begin
            sp:=@Src.Pixels32[dy,dx];
            c00:=sp^; Inc(sp);
            c01:=sp^;
            c10:=pc^;
            c11:=pc^;
          end;
          ex:=sdx and $FFFF;
          ey:=sdy and $FFFF;
          t1:=((((c01.b-c00.b)*ex)shr 16)+c00.b)and $FF;
          t2:=((((c11.b-c10.b)*ex)shr 16)+c10.b)and $FF;
          pc.b:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((c01.g-c00.g)*ex)shr 16)+c00.g)and $FF;
          t2:=((((c11.g-c10.g)*ex)shr 16)+c10.g)and $FF;
          pc.g:=(((t2-t1)*ey)shr 16)+t1;
          t1:=((((c01.r-c00.r)*ex)shr 16)+c00.r)and $FF;
          t2:=((((c11.r-c10.r)*ex)shr 16)+c10.r)and $FF;
          pc.r:=(((t2-t1)*ey)shr 16)+t1;
        end;
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
    end;
  end else
  begin
    for y:=0 to Dst.Height-1 do
    begin
      dy:=cy-y;
      sdx:=(ax+(isin*dy))+xd;
      sdy:=(ay-(icos*dy))+yd;
      for x:=0 to Dst.Width-1 do
      begin
        dx:=sdx shr 16;
        dy:=sdy shr 16;
        if(dx<Src.Width)and(dy<Src.Height)then pc^:=Src.Pixels32[dy,dx];
        Inc(sdx,icos);
        Inc(sdy,isin);
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end;
  end;
end;

procedure Transform(Src,Dst:TFastDIB;cx,cy,isin,icos:Integer;Smooth:Boolean);
begin
  case Dst.Bpp of
    8:  Transform8(Src,Dst,cx,cy,isin,icos,Smooth);
    16: Transform16(Src,Dst,cx,cy,isin,icos,Smooth);
    24: Transform24(Src,Dst,cx,cy,isin,icos,Smooth);
    32: Transform32(Src,Dst,cx,cy,isin,icos,Smooth);
  end;
end;

procedure Rotate(Src,Dst:TFastDIB;Angle:Double;Smooth:Boolean);
begin
  Transform(Src,Dst,
    Dst.Width shr 1,
    Dst.Height shr 1,
    Round(Sin(Angle*Pi/180)*65536),
    Round(Cos(Angle*Pi/180)*65536),
    Smooth);
end;

procedure Rotozoom(Src,Dst:TFastDIB;Angle:Double;Zoom:Integer;Smooth:Boolean);
begin
  Transform(Src,Dst,
    Dst.Width shr 1,
    Dst.Height shr 1,
    Round(Sin(Angle*Pi/180)*Zoom),
    Round(Cos(Angle*Pi/180)*Zoom),
    Smooth);
end;

procedure SquareWave8(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pb: PByte;
  py: PLine8;
begin
  GetMem(sx,Dst.Width shl 2);
  GetMem(sy,Dst.AbsHeight shl 2);
  for i:=0 to Dst.Width-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.AbsHeight-1 do sy[i]:=Round(Sin(i/y)*z);
  pb:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    yy:=sy[cy]+cy;
    if(yy>=0)and(yy<Src.AbsHeight)then
    begin
      py:=Src.Scanlines[yy];
      for cx:=0 to Dst.Width-1 do
      begin
        xx:=sx[cx]+cx;
        if(xx>=0)and(xx<Src.Width)then pb^:=py[xx];
        Inc(pb);
      end;
      Inc(pb,Dst.Gap);
    end else Inc(pb,Dst.BWidth);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure SquareWave16(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pw: PWord;
  py: PLine16;
begin
  GetMem(sx,Dst.Width shl 2);
  GetMem(sy,Dst.AbsHeight shl 2);
  for i:=0 to Dst.Width-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.AbsHeight-1 do sy[i]:=Round(Sin(i/y)*z);
  pw:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    yy:=sy[cy]+cy;
    if(yy>=0)and(yy<Src.AbsHeight)then
    begin
      py:=Src.Scanlines[yy];
      for cx:=0 to Dst.Width-1 do
      begin
        xx:=sx[cx]+cx;
        if(xx>=0)and(xx<Src.Width)then pw^:=py[xx];
        Inc(pw);
      end;
      pw:=Ptr(Integer(pw)+Dst.Gap);
    end else pw:=Ptr(Integer(pw)+Dst.BWidth);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure SquareWave24(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pc: PFColor;
  py: PLine24;
begin
  GetMem(sx,Dst.Width shl 2);
  GetMem(sy,Dst.AbsHeight shl 2);
  for i:=0 to Dst.Width-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.AbsHeight-1 do sy[i]:=Round(Sin(i/y)*z);
  pc:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    yy:=sy[cy]+cy;
    if(yy>=0)and(yy<Src.AbsHeight)then
    begin
      py:=Src.Scanlines[yy];
      for cx:=0 to Dst.Width-1 do
      begin
        xx:=sx[cx]+cx;
        if(xx>=0)and(xx<Src.Width)then pc^:=py[xx];
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end else pc:=Ptr(Integer(pc)+Dst.BWidth);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure SquareWave32(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pc: PFColorA;
  py: PLine32;
begin
  GetMem(sx,Dst.Width shl 2);
  GetMem(sy,Dst.AbsHeight shl 2);
  for i:=0 to Dst.Width-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.AbsHeight-1 do sy[i]:=Round(Sin(i/y)*z);
  pc:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    yy:=sy[cy]+cy;
    if(yy>=0)and(yy<Src.AbsHeight)then
    begin
      py:=Src.Scanlines[yy];
      for cx:=0 to Dst.Width-1 do
      begin
        xx:=sx[cx]+cx;
        if(xx>=0)and(xx<Src.Width)then pc^:=py[xx];
        Inc(pc);
      end;
      pc:=Ptr(Integer(pc)+Dst.Gap);
    end else pc:=Ptr(Integer(pc)+Dst.BWidth);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure SquareWave(Src,Dst:TFastDIB;x,y,z:Double);
begin
  case Dst.Bpp of
    8:  SquareWave8(Src,Dst,x,y,z);
    16: SquareWave16(Src,Dst,x,y,z);
    24: SquareWave24(Src,Dst,x,y,z);
    32: SquareWave32(Src,Dst,x,y,z);
  end;
end;

procedure RoundWave8(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pb: PByte;
begin
  GetMem(sy,Dst.Width shl 2);
  GetMem(sx,Dst.AbsHeight shl 2);
  for i:=0 to Dst.AbsHeight-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.Width-1 do sy[i]:=Round(Sin(i/y)*z);
  pb:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    xx:=sx[cy];
    for cx:=0 to Dst.Width-1 do
    begin
      yy:=sy[cx]+cy;
      if(xx>=0)and(xx<Src.Width)and(yy>=0)and(yy<Src.Height)then
        pb^:=Src.Pixels8[yy,xx];
      Inc(xx);
      Inc(pb);
    end;
    Inc(pb,Dst.Gap);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure RoundWave16(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pw: PWord;
begin
  GetMem(sy,Dst.Width shl 2);
  GetMem(sx,Dst.AbsHeight shl 2);
  for i:=0 to Dst.AbsHeight-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.Width-1 do sy[i]:=Round(Sin(i/y)*z);
  pw:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    xx:=sx[cy];
    for cx:=0 to Dst.Width-1 do
    begin
      yy:=sy[cx]+cy;
      if(xx>=0)and(xx<Src.Width)and(yy>=0)and(yy<Src.Height)then
        pw^:=Src.Pixels16[yy,xx];
      Inc(xx);
      Inc(pw);
    end;
    pw:=Ptr(Integer(pw)+Dst.Gap);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure RoundWave24(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pc: PFColor;
begin
  GetMem(sy,Dst.Width shl 2);
  GetMem(sx,Dst.AbsHeight shl 2);
  for i:=0 to Dst.AbsHeight-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.Width-1 do sy[i]:=Round(Sin(i/y)*z);
  pc:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    xx:=sx[cy];
    for cx:=0 to Dst.Width-1 do
    begin
      yy:=sy[cx]+cy;
      if(xx>=0)and(xx<Src.Width)and(yy>=0)and(yy<Src.Height)then
        pc^:=Src.Pixels24[yy,xx];
      Inc(xx);
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Dst.Gap);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure RoundWave32(Src,Dst:TFastDIB;x,y,z:Double);
var
  xx,yy,cx,cy,i: Integer;
  sx,sy: PSLut;
  pc: PFColorA;
begin
  GetMem(sy,Dst.Width shl 2);
  GetMem(sx,Dst.AbsHeight shl 2);
  for i:=0 to Dst.AbsHeight-1 do sx[i]:=Round(Sin(i/x)*z);
  for i:=0 to Dst.Width-1 do sy[i]:=Round(Sin(i/y)*z);
  pc:=Pointer(Dst.Bits);
  for cy:=0 to Dst.AbsHeight-1 do
  begin
    xx:=sx[cy];
    for cx:=0 to Dst.Width-1 do
    begin
      yy:=sy[cx]+cy;
      if(xx>=0)and(xx<Src.Width)and(yy>=0)and(yy<Src.Height)then
        pc^:=Src.Pixels32[yy,xx];
      Inc(xx);
      Inc(pc);
    end;
    pc:=Ptr(Integer(pc)+Dst.Gap);
  end;
  FreeMem(sy);
  FreeMem(sx);
end;

procedure RoundWave(Src,Dst:TFastDIB;x,y,z:Double);
begin
  case Dst.Bpp of
    8:  RoundWave8(Src,Dst,x,y,z);
    16: RoundWave16(Src,Dst,x,y,z);
    24: RoundWave24(Src,Dst,x,y,z);
    32: RoundWave32(Src,Dst,x,y,z);
  end;
end;

end.
