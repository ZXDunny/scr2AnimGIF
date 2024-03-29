program Scr2AnimGIF;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, ShellAPI, System.SysUtils, System.Classes, FastDIB, FastFiles, FastFX, FastSize, SpeccyScreen;

var
  Surface, BorderDIB, ScaleDIB: TFastDIB;
  Audio: Array[0..1024*1024] of Byte;
  Env: TEnvironmentInfo;
  Loader_Header, Loader_Data: TLoaderInfo;
  Filename, OutFilename, Outmp4Filename, OutwavFilename, s, ns: String;
  WAVHeader: AnsiString;
  FStream, wavFile: TFileStream;
  DisplayPalette: TFColorTable;
  i, preload_delay, prepilot_delay, BorderSize, bw, bh, bx, by, finalBorder, OldStage, BitCount,
  TotalBits, Avg, TotalTs, ZeroLen, OneLen, FixedPulseLen, Scale: Integer;
  Optimise_Data, FixedLen, enableSound, mp4Out: Boolean;
  AudioSize, WAVRIFFSize: Longword;
  CheckSum: Byte;

Const

  help: array[0..22] of String = (
    'Speccy screen file (.scr) converter to animated GIF files.',
    '',
    'SCR2AnimGIF.exe Filename -o Outfilename -hw (48k/128k) -hiss -wobble -pa/pb/pp -header [name] -border (full/partial/small/none) -opt -cls n -attrs -fb n',
    '',
    '-o Specify an output filename. If not specified, input filename is assumed and given a .gif extension.',
    '-hw Specify hardware - 48k or 128k. Affects border stripe sizes and speed.',
    '-hiss enable tape hiss - roughs up the border edges a little.',
    '-wobble enables tape wobble - a wowing effect',
    '-pa -b -pp Specifies a pause in seconds - pa = pause after load, pb = pause before load, pp = pause while seeking pilot (usually 1 second for ROM loader)',
    '-header adds a header block. Optional (up to ten characters) name can be specified and will appear after "Bytes:" before screen loads',
    '-border specifies border size. full = 352x296, partial = 320x240, small = 4 pixel wide border, none = just PAPER area, no border stripes.',
    '-opt if present, optimises the display area for loading speed.',
    '-cls n Allows you to specify the starting screen colour. Uses an ATTR byte, so 56 by default (black ink, white paper, no bright, no flash)',
    '-attrs - only load the attributes from the .scr file. Manic Miner looks good with this.',
    '-fb lets you specify the final border colour after loading is complete. Default 7 (white).',
    '-sound creates a wav file of the loading sound',
    '-volume sets volume (0 to 255)',
    '-lowpass adds a low pass sound filter',
    '-mp4 outputs an mp4 video created from the gif and (if you have the -sound switch enabled) with full sound.',
    'This requires FFMpeg.exe to be present somewhere in your path - and it MUST be the correct bit version (x86 or x64) depending on which version of the Scr2AnimGIF executable you are running.',
    '-scale n scales to the selected size (2, 3, 4, etc)',
    '',
    'FLASH and BRIGHT attributes work as you would expect.');

  SetCount: Array [0..255] of Byte =
     (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3,
      3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4,
      3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6,
      6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5,
      3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4,
      4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7,
      6, 7, 7, 8);

  TFSpecBlack:    TFcolor = (b:0;g:0;r:0);
  TFSpecBlue:     TFColor = (b:202;g:0;r:0);
  TFSpecRed:      TFColor = (b:0;g:0;r:202);
  TFSpecMagenta:  TFColor = (b:202;g:0;r:202);
  TFSpecGreen:    TFColor = (b:0;g:202;r:0);
  TFSpecCyan:     TFColor = (b:202;g:202;r:0);
  TFSpecYellow:   TFColor = (b:0;g:202;r:202);
  TFSpecWhite:    TFColor = (b:197;g:197;r:197);
  TFSpecBlueB:    TFColor = (b:255;g:0;r:0);
  TFSpecRedB:     TFColor = (b:0;g:0;r:255);
  TFSpecMagentaB: TFColor = (b:255;g:0;r:255);
  TFSpecGreenB:   TFColor = (b:0;g:255;r:0);
  TFSpecCyanB:    TFColor = (b:255;g:255;r:0);
  TFSpecYellowB:  TFColor = (b:0;g:255;r:255);
  TFSpecWhiteB:   TFColor = (b:255;g:255;r:255);

  Procedure BuildPalette(Clrs: Array of TFColor);
  Var
    F: Integer;
  Begin
    For F := 0 To 15 Do begin
       DisplayPalette[F].r := Clrs[F].r;
       DisplayPalette[F].g := Clrs[F].g;
       DisplayPalette[F].b := Clrs[F].b;
    End;
  End;

  Procedure Optimise;
  Var
    X, Y, Count, CountInverted, Idx, Addr: Integer;
    Bytes, BytesInverted: Array[0..8] of Byte;
  Begin
    For Y := 0 To 23 Do
      For X := 0 To 31 Do Begin
        Addr := ScreenAddresses[Y * 8] + X;
        For Idx := 0 To 7 Do Begin
          Bytes[Idx] := Byte(Screen_Data[Addr + (Idx * 256)]);
          BytesInverted[Idx] := Bytes[Idx] Xor 255;
        End;
        Bytes[8] := Byte(Screen_Data[6144 + (Y * 32) + X]);
        If (Bytes[8] And 7 = (Bytes[8] Shr 3) And 7) Then Begin
          For Idx := 0 To 7 Do
            Bytes[Idx] := 0;
          Bytes[8] := Bytes[8] And 127;
        End;
        BytesInverted[8] := ((Bytes[8] And 7) Shl 3) + ((Bytes[8] And 56) shr 3) + (Bytes[8] And 192);
        Count := 0;
        CountInverted := 0;
        For Idx := 0 To 7 Do Begin
          Inc(Count, SetCount[Bytes[Idx]]);
          Inc(CountInverted, SetCount[BytesInverted[Idx]]);
        End;
        If CountInverted < Count Then Begin
          For Idx := 0 To 7 Do
            Screen_Data[Addr + (Idx * 256)] := BytesInverted[Idx];
          Screen_Data[6144 + (Y * 32) + X] := BytesInverted[8];
        End;
    End;
  End;

  function ExecuteAndWait(Const CommandLine: string): Boolean;
  var
    StartupInfo: TStartupInfo;
    AErrorOrExitCode: Cardinal;
    ProcessInfo: TProcessInformation;
    S : String;
  begin
    FillChar(StartupInfo,Sizeof(StartupInfo),0);
    StartupInfo.cb := Sizeof(StartupInfo);
    S := CommandLine;
    UniqueString(S);
    if not CreateProcess(nil, PChar(S), nil, nil, False, NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo,ProcessInfo) then Begin
      Result := False;
      AErrorOrExitCode := GetLastError;
      if GetLastError = 50 Then
        WriteLn('Cannot open FFMpeg - wrong arch?');
      Halt;
    end else begin
      Result := True;
      WaitforSingleObject(ProcessInfo.hProcess,INFINITE);
      GetExitCodeProcess(ProcessInfo.hProcess, AErrorOrExitCode);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;
  end;

begin
  try

    WriteLn('Scr2AnimGIF v1.35 By Paul Dunn (C) 2022');
    WriteLn('');

    preLoad_delay := -1;
    prePilot_delay := -1;
    Optimise_Data := False;
    FinalBorder := -1;
    BorderSize := 0;
    enableSound := False;
    FixedLen := False;
    mp4Out := False;
    Scale := 1;

    Env.HardwareModel := h48k;
    Env.Programmer := pgmNone;
    Env.TapeWobble := False;
    Env.TapeHiss := False;
    Env.Sound_Enabled := False;
    Env.PauseLen := 5;
    Env.LongFilenames := False;
    Env.Chuntey := False;
    Env.DoHeader := False;
    Env.AttrsOnly := False;
    Env.CLSAttr := 56;
    Env.Sound_Volume := 255;
    Env.LowPass := False;

    // Gather command line options
    // filename
    // -o out filename (uses filename.gif if omitted)
    // -hw 48k/128k/plus2/plus3
    // -hiss tape hiss
    // -wobble tape wobble
    // -pb -pa -pp - length of pause in secs before/after/pilot wait load
    // -header [name] - do a tape header, with optional name (otherwise truncate to 10 chars from filename)
    // -border full/partial/small/none
    // -opt add optimisation step - reduce number of 1 pulses to speed up loading
    // -addr address to load the data to. Truncates if necessary.
    // -attr - only load ATTRs. Overrides -addr.
    // -cls b - clear the screen to the chosen byte value before loading.
    // -fb final border colour to end on while the last pause is happening
    // -mp4 - output mp4 format
    // -sound - output mp4 or wav with sound

    i := 1;
    While i <= ParamCount Do Begin
      s := LowerCase(ParamStr(i));
      ns := Lowercase(ParamStr(i+1));

      If Lowercase(ParamStr(i)) = '-o' Then Begin
        OutFilename := ParamStr(i +1);
        Inc(i);
      End Else
        If Lowercase(ParamStr(i)) = '-hw' Then Begin
          If ns = '48k' then
            Env.HardwareModel := h48k
          else
            If ns = '128k' then
                Env.HardwareModel := h128k
            else Begin
              WriteLn('Invalid hardware type');
              Halt;
            End;
          Inc(i);
        End Else
          If Lowercase(ParamStr(i)) = '-hiss' Then Begin
            Env.TapeHiss := True;
          End Else
            If Lowercase(ParamStr(i)) = '-wobble' Then Begin
              Env.TapeWobble := True;
            End Else
              If Lowercase(ParamStr(i)) = '-pa' Then Begin
                Env.PauseLen := StrToFloat(ns);
                Inc(i);
              End Else
                If Lowercase(ParamStr(i)) = '-pb' Then Begin
                  PreLoad_Delay := StrToInt(ns);
                  Inc(i);
                End Else
                  If Lowercase(ParamStr(i)) = '-pp' Then Begin
                    PrePilot_Delay := StrToInt(ns);
                    Inc(i);
                  End Else
                    If (Lowercase(ParamStr(i)) = '-header') Then Begin
                      Env.DoHeader := True;
                      If  (ns <> '') and (ns[1] <> '-') Then Begin
                        Env.HeaderName := ParamStr(i+1);
                        Inc(i);
                      End;
                    End Else
                      If Lowercase(ParamStr(i)) = '-border' Then Begin
                        If ns = 'full' then
                          BorderSize := 0
                        Else
                          If ns = 'partial' Then
                            BorderSize := 1
                          Else
                            If ns = 'small' Then
                              BorderSize := 2
                            Else
                              If ns = 'none' Then
                                BorderSize := 3
                              Else Begin
                                WriteLn('Invalid BORDER size');
                                Halt;
                              End;
                        Inc(i);
                      End Else
                        If Lowercase(ParamStr(i)) = '-opt' Then Begin
                          Optimise_Data := True;
                        End Else
                          If Lowercase(ParamStr(i)) = '-cls' Then Begin
                            Env.CLSAttr := StrToInt(ns);
                            Inc(i);
                          End Else
                            If Lowercase(ParamStr(i)) = '-attrs' Then Begin
                              Env.AttrsOnly := True;
                            End Else
                              If Lowercase(ParamStr(i)) = '-fb' Then Begin
                                finalBorder := StrToInt(ns);
                                If (finalBorder < 0) or (finalBorder > 7) Then Begin
                                  WriteLn('Invalid BORDER colour');
                                  Halt;
                                End;
                                Inc(i);
                              End Else
                                If Lowercase(ParamStr(i)) = '-mp4' Then Begin
                                  mp4Out := True;
                                End Else
                                  If Lowercase(ParamStr(i)) = '-sound' Then Begin
                                    enableSound := True;
                                  End Else
                                    if Lowercase(ParamStr(i)) = '-fixed' Then Begin
                                      FixedLen := True;
                                      FixedPulseLen := StrToInt(ns);
                                      If (FixedPulseLen < 0) or (FixedPulseLen > 10000) Then Begin
                                        WriteLn('Invalid fixed pulse length');
                                        Halt;
                                      End;
                                      Inc(i);
                                    End Else
                                      If Lowercase(ParamStr(i)) = '-?' Then Begin
                                        for i := 0 to High(Help) do
                                          WriteLn(Help[i]);
                                        Halt;
                                      End Else
                                        if Lowercase(ParamStr(i)) = '-scale' Then Begin
                                          Scale := StrToInt(ns);
                                          if Scale < 1 Then Begin
                                            WriteLn('Invalid scaling value');
                                            Halt;
                                          End;
                                          Inc(i);
                                        End Else
                                          If Lowercase(ParamStr(i)) = '-lowpass' Then Begin
                                            env.LowPass := True;
                                          end else
                                            if Lowercase(ParamStr(i)) = '-volume' Then Begin
                                              Env.Sound_Volume := StrToInt(ns);
                                              if (Env.Sound_Volume < 0) or (Env.Sound_Volume > 255) Then Begin
                                                WriteLn('Invalid volume value (0..255)');
                                                Halt;
                                              End;
                                              Inc(i);
                                            End Else
                                              Filename := ParamStr(i);
      Inc(i);
    End;

    // ROM loader

    FillChar(Loader_Header, SizeOf(TLoaderInfo), 0);
    Loader_Header.Pilot_Border_1 := 5;
    Loader_Header.Pilot_Border_2 := 2;
    Loader_Header.Pilot_Repeats := 8063;
    Loader_Header.Pilot_Tone_Length := 2168;
    Loader_Header.Pilot_Loops := 1;
    Loader_Header.Sync1_Length := 667;
    Loader_Header.Sync2_Length := 735;
    Loader_Header.Data_Border_1 := 1;
    Loader_Header.Data_Border_2 := 6;
    Loader_Header.Data_One_Length := 1710;
    Loader_Header.Data_Zero_Length := 855;
    Loader_Header.Data_Pause_Length := 0;
    Loader_Header.PreLoad_Delay := 20;
    Loader_Header.PreHeader_Delay := 50;
    Loader_Header.Data_Length := 19;
    Loader_Header.FinalBorder := 2;

    FillChar(Loader_Data, SizeOf(TLoaderInfo), 0);
    Loader_Data.Pilot_Border_1 := 5;
    Loader_Data.Pilot_Border_2 := 2;
    Loader_Data.Pilot_Repeats := 3223;
    Loader_Data.Pilot_Tone_Length := 2168;
    Loader_Data.Pilot_Loops := 1;
    Loader_Data.Sync1_Length := 667;
    Loader_Data.Sync2_Length := 735;
    Loader_Data.Data_Border_1 := 1;
    Loader_Data.Data_Border_2 := 6;
    Loader_Data.Data_One_Length := 1710;
    Loader_Data.Data_Zero_Length := 855;
    Loader_Data.Data_Pause_Length := 2000;
    Loader_Data.PreLoad_Delay := 0;
    Loader_Data.PreHeader_Delay := 50;
    Loader_Data.Data_Length := 6914;
    Loader_Data.FinalBorder := 7;

{    // Speedlock 1

    FillChar(Loader_Header, SizeOf(TLoaderInfo), 0);
    Loader_Header.Pilot_Border_1 := 5;
    Loader_Header.Pilot_Border_2 := 2;
    Loader_Header.Pilot_Repeats := 228;
    Loader_Header.Pilot_Tone_Length := 2168;
    Loader_Header.Pilot_Loops := 32;
    Loader_Header.Pilot_Click_length := 714;
    Loader_Header.Pilot_Click_Repeats := 2;
    Loader_Header.Sync1_Length := 667;
    Loader_Header.Sync2_Length := 735;
    Loader_Header.Data_Border_1 := 1;
    Loader_Header.Data_Border_2 := 6;
    Loader_Header.Data_One_Length := 1129;
    Loader_Header.Data_Zero_Length := 564;
    Loader_Header.Data_Pause_Length := 928;
    Loader_Header.PreLoad_Delay := 0;
    Loader_Header.PreHeader_Delay := 50;
    Loader_Header.Data_Length := 17;
    Loader_Header.FinalBorder := 2;

    FillChar(Loader_Data, SizeOf(TLoaderInfo), 0);
    Loader_Data.Pilot_Border_1 := 5;
    Loader_Data.Pilot_Border_2 := 2;
    Loader_Data.Pilot_Repeats := 228;
    Loader_Data.Pilot_Tone_Length := 2168;
    Loader_Data.Pilot_Loops := 32;
    Loader_Data.Pilot_Click_length := 714;
    Loader_Data.Pilot_Click_Repeats := 2;
    Loader_Data.Sync1_Length := 667;
    Loader_Data.Sync2_Length := 735;
    Loader_Data.Data_Border_1 := 1;
    Loader_Data.Data_Border_2 := 6;
    Loader_Data.Data_One_Length := 1129;
    Loader_Data.Data_Zero_Length := 564;
    Loader_Data.Data_Pause_Length := 2000;
    Loader_Data.PreLoad_Delay := 50;
    Loader_Data.PreHeader_Delay := 50;
    Loader_Data.Data_Length := 6912;
    Loader_Data.FinalBorder := 0;
}
{    // Speedlock 4

    FillChar(Loader_Header, SizeOf(TLoaderInfo), 0);
    Loader_Header.Pilot_Border_1 := 5;
    Loader_Header.Pilot_Border_2 := 2;
    Loader_Header.Pilot_Repeats := 8064;
    Loader_Header.Pilot_Tone_Length := 2168;
    Loader_Header.Pilot_Loops := 1;
    Loader_Header.Sync1_Length := 667;
    Loader_Header.Sync2_Length := 735;
    Loader_Header.Data_Border_1 := 1;
    Loader_Header.Data_Border_2 := 6;
    Loader_Header.Data_One_Length := 1710;
    Loader_Header.Data_Zero_Length := 835;
    Loader_Header.Data_Pause_Length := 928;
    Loader_Header.PreLoad_Delay := 0;
    Loader_Header.PreHeader_Delay := 50;
    Loader_Header.Data_Length := 17;
    Loader_Header.FinalBorder := 2;

    FillChar(Loader_Data, SizeOf(TLoaderInfo), 0);
    Loader_Data.Pilot_Border_1 := 0;
    Loader_Data.Pilot_Border_2 := 2;
    Loader_Data.Pilot_Repeats := 1595;
    Loader_Data.Pilot_Tone_Length := 2099;
    Loader_Data.Pilot_Loops := 1;
    Loader_Data.Sync1_Length := 667;
    Loader_Data.Sync2_Length := 735;
    Loader_Data.Data_Border_1 := 1;
    Loader_Data.Data_Border_2 := 0;
    Loader_Data.Data_One_Length := 1508;
    Loader_Data.Data_Zero_Length := 753;
    Loader_Data.Data_Pause_Length := 2000;
    Loader_Data.PreLoad_Delay := 0;
    Loader_Data.PreHeader_Delay := 0;
    Loader_Data.Data_Length := 6912;
    Loader_Data.FinalBorder := 0;
}

    If PreLoad_Delay >= 0 Then
      If Env.DoHeader Then
        Loader_Header.PreLoad_Delay := PreLoad_Delay
      Else
        Loader_Data.PreLoad_Delay := PreLoad_Delay;

    If PrePilot_Delay >= 0 Then
      If Env.DoHeader Then
        Loader_Header.PreHeader_Delay := PrePilot_Delay
      Else
        Loader_Data.PreHeader_Delay := PrePilot_Delay;

    If Env.AttrsOnly Then Begin
      Loader_Data.Data_Length := 769;
      Env.StartAddress := 6144;
    End;

    If finalBorder > -1 Then
      Loader_Data.FinalBorder := finalBorder;

    If Loader_Data.Data_Length + Env.StartAddress > 6914 Then
      Loader_Data.Data_Length := (6912 - Env.StartAddress) + 2;

    BuildPalette([TFSpecBlack, TFSpecBlue,  TFSpecRed,  TFSpecMagenta,  TFSpecGreen,  TFSpecCyan,  TFSpecYellow,  TFSpecWhite,
                  TFSpecBlack, TFSpecBlueB, TFSpecRedB, TFSpecMagentaB, TFSpecGreenB, TFSpecCyanB, TFSpecYellowB, TFSpecWhiteB]);

    Case BorderSize of
      0: // Full
        Begin
          bw := 352;
          bh := 296;
        End;
      1: // Partial
        Begin
          bw := 320;
          bh := 240;
        End;
      2: // Small
        Begin
          bw := 264;
          bh := 200;
        End;
      3: // None
        Begin
          bw := 256;
          bh := 192;
        End;
    Else
      Begin
        bw := 352;
        bh := 296;
      End;
    End;

    bx := (352 - bw) Div 2;
    if BorderSize > 0 Then
      by := 48 - ((bh - 192) Div 2)
    Else
      by := 0;

    SUrface := TFastDIB.Create;
    Surface.SetSize(bw, bh, 8);
    Surface.Colors := @DisplayPalette;
    Surface.UpdateColors;

    BorderDIB := TFastDIB.Create;
    BorderDIB.SetSize(352, 296, 8);
    BorderDIB.Colors := @DisplayPalette;
    BorderDIB.UpdateColors;

    FStream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
    FStream.Read(Screen_Data[1], 6912);
    FStream.Free;

    Checksum := 0;
    Screen_Data[0] := $FF;
    For i := 0 to 6912 do
      CheckSum := CheckSum Xor Screen_Data[i];
    Screen_Data[6913] := CheckSum;

    If outFilename = '' Then
      OutFilename := ChangeFileExt(Filename, '.gif');

    If Env.HeaderName = '' Then Env.HeaderName := Copy(ExtractFileName(Filename), 1, 10);
    MakeHeader(Env.HeaderName);

    If FixedLen Then Begin
      BitCount := 0;
      For i := 0 To Length(Header_Data) -1 Do
        Inc(BitCount, SetCount[Ord(Header_Data[i])]);
      For i := 0 To Length(Screen_Data) -1 Do
        Inc(BitCount, SetCount[Ord(Screen_Data[i])]);
      TotalBits := (6914 + 19) * 8;
      TotalTs := Loader_Data.Data_Zero_Length * TotalBits * 2;
      ZeroLen := Round(TotalTs/(BitCount + BitCount + (TotalBits - BitCount)) / 2);
      OneLen := FixedPulseLen * 2;
      Loader_Header.Data_One_length := OneLen;
      Loader_Header.Data_Zero_Length := ZeroLen;
      Loader_Data.Data_One_length := OneLen;
      Loader_Data.Data_Zero_Length := ZeroLen;
    End;

    InitScreenSaver(BorderDIB.Bits, @Audio[0], @Env);
    NewLoad(Filename, @Loader_Header, @Loader_Data, False);

    if mp4Out then
      WriteLn('Creating ' + ChangeFileExt(OutFilename, '.mp4'))
    else
      WriteLn('Creating ' + OutFilename);

    If Optimise_Data Then Optimise;

    OldStage := -1;

    // Initial frame

    FillChar(Audio, 1024 * 1024, 128);
    SpeccyScreen.Frame;
    Flop(BorderDIB);
    BorderDIB.Draw(Surface.hDc, -bx, -by);

    If Scale > 1 Then Begin
      ScaleDIB := TFastDIB.Create;
      ScaleDIB.SetSize(bw * Scale, bh * Scale, 8);
      ScaleDIB.Colors := @DisplayPalette;
      ScaleDIB.UpdateColors;
      FastReSize(Surface, ScaleDIB);
      SaveGIFFile(ScaleDIB, OutFilename, True, 2, True);
    End Else
      SaveGIFFile(Surface, OutFilename, True, 2, True);

    // Now continue.

    if enableSound or mp4Out Then Begin
      OutWAVFilename := ChangeFileExt(OutFilename, '.wav');
      wavfile := TFileStream.Create(OutWAVFilename, fmCreate);
      WAVHeader := 'RIFF' + #0#0#0#0 + 'WAVE' + 'fmt ' + #16#0#0#0 + #1#0 + #1#0 + #68#172#0#0 + #68#172#0#0 + #1#0 + #8#0 + 'data' + #0#0#0#0;
      wavFile.Write(WAVHeader[1], Length(WAVHeader));
      wavFile.Write(Audio, SoundSize);
      Inc(AudioSize, SoundSize);
      SoundPos := @Audio[0];
      FillChar(SoundPos^, 1024 * 1024, 128);
      SoundSize := 0;
    End Else Begin
      SoundPos := @Audio[0];
      SoundSize := 0;
    End;

    While True Do Begin

      if OldStage <> Integer(Stage) Then Begin
        OldStage := Integer(Stage);
        Case Stage of
          lsReset, lsProgram, lsPreLoad, lsPostProgram:
            Write('Working: Pre-load pause   ' + #13);
          lsPrePilot:
            Write('Working: Waiting for Pilot' + #13);
          lsPilot:
            Write('Working: Pilot tones      ' + #13);
          lsData:
            Write('Working: Data bytes       ' + #13);
          lsPause:
            Write('Working: Post-data pause  ' + #13);
          lsFinish, lsQuit:
            If mp4Out Then
              Write('Working: Encoding       ' + #13)
            Else
              Write('Finished!               ' + #13);
        End;
      End;

      SpeccyScreen.Frame;
      If InProgress Then Begin
        Flop(BorderDIB);
        BorderDIB.Draw(Surface.hDc, -bx, -by);
        If Scale > 1 Then Begin
          FastReSize(Surface, ScaleDIB);
          AddGIFFrame(ScaleDIB, OutFilename, 2, True);
        End Else
          AddGIFFrame(Surface, OutFilename, 2, True);
        if enableSound Then Begin
          wavFile.Write(Audio, SoundSize);
          Inc(AudioSize, SoundSize);
          SoundPos := @Audio[0];
          FillChar(SoundPos^, 1024 * 1024, 128);
          SoundSize := 0;
        end Else Begin
          if mp4Out Then Begin
            SoundPos := @Audio[0];
            FillChar(SoundPos^, 1024 * 1024, 128);
            wavFile.Write(Audio, SoundSize);
            Inc(AudioSize, SoundSize);
            SoundSize := 0;
          End Else Begin
            SoundPos := @Audio[0];
            SoundSize := 0;
          End;
        End;
      End Else
        Break;
    End;

    AddGIFFrame(nil, OutFilename, 0, True);
    if enableSound or mp4Out Then Begin
      wavFile.Seek(4, soFromBeginning);
      WAVRIFFSize := AudioSize + (44 - 8);
      wavFile.Write(WAVRIFFSize, 4);
      wavFile.Seek(40, soFromBeginning);
      wavFile.Write(AudioSize, 4);
      wavFile.free;
    end;

    if mp4Out Then Begin
      Outmp4Filename := ChangeFileExt(OutFilename, '.mp4');
      if FileExists(Outmp4Filename) Then DeleteFile(Outmp4Filename);
      ExecuteAndWait('ffmpeg.exe -hide_banner -loglevel fatal -i "' + OutFilename + '" -i "' + OutwavFilename + '" -r 50 -vsync cfr -preset veryslow -tune animation -crf 22 -vf colormatrix=bt601:bt709 -pix_fmt yuv420p "' + Outmp4Filename +'"');
      if not enableSound then
        if FileExists(OutWAVFilename) Then
          DeleteFile(OutWAVFilename);
    End;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
