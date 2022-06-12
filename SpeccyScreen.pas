// Copyright (C) 2009 Paul Dunn
//
// This file is part of the SCREEN$ screensaver.
//
// SCREEN$ is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SCREEN$ is distributed in the hope that it will be entertaining,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SCREEN$.  If not, see <http://www.gnu.org/licenses/>.

unit SpeccyScreen;

// Generates the screensaver display
// Specify the parameters for the screen - loader type, screen data and handle to a 352x296x8 DIB,
// and then call Frame() successively for each frame until Frame() Sets the InProgress var to FALSE.

interface

Type

  // Replacement types for those declared in Windows.pas

  pByte =        ^Byte;
  pLongWord =    ^LongWord;
  TPoint = record
    x: Longint;
    y: Longint;
  end;

  // Structures for screensaver options

  T48kMode =        (mdRandom, mdNone, md48BASIC, mdSPECTRUM, mdUSR0);
  TResetStage =     (rsStart, rsFill2, rsClear, rs128kClear, rs128kMenu, rsCLS, rsMessage, rsPause);
  TMenuStage =      (msMessage1, msMessage2, msMessage3, msMessage4, msMenuStrip, msOptions1, msOptions2,
                     msOptions3, msLeftBorder, msBottom1, msBottom2, msRightBorder, msHighlight);
  TDataStage =      (dsSync1, dsSync2, dsData1, dsData2);
  TDataType =       (dtHeader, dtData);
  TLoaderStage =    (lsReset, lsProgram, lsPreLoad, lsPostProgram, lsPrePilot, lsPilot, lsData, lsPause, lsFinish, lsQuit);
  TChunteyType =    (ctForward, ctBackward);

  THardware =       (h16k, h48k, h128k, hPlus2, hPlus2a, hPlus3, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0);
  TProgrammer =     (pgmNone, pgmProgram, pgmDirectCommand);
  TProgramStage =   (ps48kBegin, ps48kCommand, ps48kClearLower, ps48kList, ps128kBegin,
                     psMenuChoose, ps128kClear, ps128kCommand, ps128kDone, ps128kTo48k, ps128kRUN);

  TEnvironmentInfo = Record
     HardwareModel: THardware;              // The hardware used in this screensaver
     Programmer: TProgrammer;               // Does the "ghost user" type a prog, or LOAD "" CODE?
     Mode48k: T48kMode;                     // Does this programmer use 48k mode in the 128k models? If so, how? 48k mode, USR0 mode or SPECTRUM?
     ResetMethod: Integer;                  // Reset options. -1 = Never Reset, 0 = at random, X = after x screens?
     CLS: Integer;                          // CLS after how many screens? 0 = None, 1 = every screen, etc
     Looped: Integer;                       // Looped? 0 = no, -1 = loop forever, n = loop n times and then finish.
     TapeWobble: Boolean;                   // Apply old-tape-deck style wobbling in pilot tones?
     TapeHiss: Boolean;                     // Apply old-tape style hissing to the sound?
     Sound_Enabled: Boolean;                // User wants sound? He must be mad.
     Sound_Volume: Integer;                 // The volume of the loading sounds etc - 0..255
     RandomHWAfterReset: Boolean;           // Choose Random hardware after a reset?
     PauseLen: Extended;                    // Pause, in seconds, after each screen. 0 = 1 Frame.
     LongFilenames: Boolean;                // If False, then filenames are truncated to 10 chars
     Chuntey: Boolean;                      // Are we expecting the chuntey to disrupt?
     DoHeader: Boolean;                     // Do a header load, or make it headerless?
     AttrsOnly: Boolean;                    // Only load ATTRS - for manic miner style screens that just use attrs and no pixel data
     CLSAttr: Byte;                         // colour to clear the screen to before loading
     HeaderName: String;                    // Name to display after the "Bytes: " text. Maximum of 10 chars
     StartAddress: Integer;                 // Address within the screen display to start loading data at
  End;
  pEnvironmentInfo = ^TEnvironmentInfo;

  TLoaderInfo = Record
     Pilot_Border_1,                        // Border colour values.
     Pilot_Border_2,                        // Two per section, for pulse flips.
     Pilot_Click_Length,                    // For a "clicking" pilot, the length of the click in Ts
     Pilot_Click_Repeats,                   // And the number of clicks to perform for each "click"
     Pilot_Tone_Length,                     // The pilot tone pulse length in Ts
     Pilot_Repeats,                         // The number of Pilot pulses in the pilot
     Pilot_Loops,                           // For clicking pilots, the number of times to loop the tone/click group
     Sync1_Length,                          // Length of the first sync pulse
     Sync2_Length,                          // Length of the second sync pulse
     Data_Border_1,
     Data_Border_2,
     Data_One_Length,                       // Length of a "one" pulse in Ts
     Data_Zero_Length,                      // Length of a "zero" pulse in Ts
     Data_Length,                           // Size of the data block
     PreLoad_Delay,                         // Delay before commencing the load in frames
     PreHeader_Delay,                       // Time in frames spent waiting for a pilot - flashing border
     Data_Pause_Length: Integer;            // Pause in Frames after the data.
     FinalBorder: Integer;                  // The colour of the border after loading the screen data.
  End;
  pLoaderInfo = ^TLoaderInfo;

  TPulse = LongInt;
  TPulseSequence = Record
     NumPulses: LongInt;
     PulseLength: TPulse;
  End;
  TPilotInfo = Record
     NumLoops: LongInt;
     NumPulseSequences: LongInt;
     PulseSequences: Array of TPulseSequence;
     NumBorders: LongInt;
     BorderList: Array of Byte;
  End;
  TSyncInfo = Record
     NumSyncPulseSequences: LongInt;
     SyncPulseList: Array of TPulseSequence;
  End;
  TDataInfo = Record

  End;
  TTapeBlock = Record
     PilotInfo: TPilotInfo;
     SyncInfo: TSyncInfo;
     DataInfo: TDataInfo;
  End;
  TLoader = Record
     HeaderBlock: TTapeBlock;
     DataBlock: TTapeBlock;
  End;


Const

  // The character set

  CharacterSet: Array[0..815] of Byte =
  (0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 16, 16, 0, 16, 0, 0, 36, 36, 0, 0, 0, 0, 0,
   0, 36, 126, 36, 36, 126, 36, 0, 0, 8, 62, 40, 62, 10, 62, 8, 0, 98, 100, 8, 16, 38, 70, 0,
   0, 16, 40, 16, 42, 68, 58, 0, 0, 8, 16, 0, 0, 0, 0, 0, 0, 4, 8, 8, 8, 8, 4, 0,
   0, 32, 16, 16, 16, 16, 32, 0, 0, 0, 20, 8, 62, 8, 20, 0, 0, 0, 8, 8, 62, 8, 8, 0,
   0, 0, 0, 0, 0, 8, 8, 16, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 0, 0, 24, 24, 0,
   0, 0, 2, 4, 8, 16, 32, 0, 0, 60, 70, 74, 82, 98, 60, 0, 0, 24, 40, 8, 8, 8, 62, 0,
   0, 60, 66, 2, 60, 64, 126, 0, 0, 60, 66, 12, 2, 66, 60, 0, 0, 8, 24, 40, 72, 126, 8, 0,
   0, 126, 64, 124, 2, 66, 60, 0, 0, 60, 64, 124, 66, 66, 60, 0, 0, 126, 2, 4, 8, 16, 16, 0,
   0, 60, 66, 60, 66, 66, 60, 0, 0, 60, 66, 66, 62, 2, 60, 0, 0, 0, 0, 16, 0, 0, 16, 0,
   0, 0, 16, 0, 0, 16, 16, 32, 0, 0, 4, 8, 16, 8, 4, 0, 0, 0, 0, 62, 0, 62, 0, 0,
   0, 0, 16, 8, 4, 8, 16, 0, 0, 60, 66, 4, 8, 0, 8, 0, 0, 60, 74, 86, 94, 64, 60, 0,
   0, 60, 66, 66, 126, 66, 66, 0, 0, 124, 66, 124, 66, 66, 124, 0, 0, 60, 66, 64, 64, 66, 60, 0,
   0, 120, 68, 66, 66, 68, 120, 0, 0, 126, 64, 124, 64, 64, 126, 0, 0, 126, 64, 124, 64, 64, 64, 0,
   0, 60, 66, 64, 78, 66, 60, 0, 0, 66, 66, 126, 66, 66, 66, 0, 0, 62, 8, 8, 8, 8, 62, 0,
   0, 2, 2, 2, 66, 66, 60, 0, 0, 68, 72, 112, 72, 68, 66, 0, 0, 64, 64, 64, 64, 64, 126, 0,
   0, 66, 102, 90, 66, 66, 66, 0, 0, 66, 98, 82, 74, 70, 66, 0, 0, 60, 66, 66, 66, 66, 60, 0,
   0, 124, 66, 66, 124, 64, 64, 0, 0, 60, 66, 66, 82, 74, 60, 0, 0, 124, 66, 66, 124, 68, 66, 0,
   0, 60, 64, 60, 2, 66, 60, 0, 0, 254, 16, 16, 16, 16, 16, 0, 0, 66, 66, 66, 66, 66, 60, 0,
   0, 66, 66, 66, 66, 36, 24, 0, 0, 66, 66, 66, 66, 90, 36, 0, 0, 66, 36, 24, 24, 36, 66, 0,
   0, 130, 68, 40, 16, 16, 16, 0, 0, 126, 4, 8, 16, 32, 126, 0, 0, 14, 8, 8, 8, 8, 14, 0,
   0, 0, 64, 32, 16, 8, 4, 0, 0, 112, 16, 16, 16, 16, 112, 0, 0, 16, 56, 84, 16, 16, 16, 0,
   0, 0, 0, 0, 0, 0, 0, 255, 0, 28, 34, 120, 32, 32, 126, 0, 0, 0, 56, 4, 60, 68, 60, 0,
   0, 32, 32, 60, 34, 34, 60, 0, 0, 0, 28, 32, 32, 32, 28, 0, 0, 4, 4, 60, 68, 68, 60, 0,
   0, 0, 56, 68, 120, 64, 60, 0, 0, 12, 16, 24, 16, 16, 16, 0, 0, 0, 60, 68, 68, 60, 4, 56,
   0, 64, 64, 120, 68, 68, 68, 0, 0, 16, 0, 48, 16, 16, 56, 0, 0, 4, 0, 4, 4, 4, 36, 24,
   0, 32, 40, 48, 48, 40, 36, 0, 0, 16, 16, 16, 16, 16, 12, 0, 0, 0, 104, 84, 84, 84, 84, 0,
   0, 0, 120, 68, 68, 68, 68, 0, 0, 0, 56, 68, 68, 68, 56, 0, 0, 0, 120, 68, 68, 120, 64, 64,
   0, 0, 60, 68, 68, 60, 4, 6, 0, 0, 28, 32, 32, 32, 32, 0, 0, 0, 56, 64, 56, 4, 120, 0,
   0, 16, 56, 16, 16, 16, 12, 0, 0, 0, 68, 68, 68, 68, 56, 0, 0, 0, 68, 68, 40, 40, 16, 0,
   0, 0, 68, 84, 84, 84, 40, 0, 0, 0, 68, 40, 16, 40, 68, 0, 0, 0, 68, 68, 68, 60, 4, 56,
   0, 0, 124, 8, 16, 32, 124, 0, 0, 14, 8, 48, 8, 8, 14, 0, 0, 8, 8, 8, 8, 8, 8, 0,
   0, 112, 16, 12, 16, 16, 112, 0, 0, 20, 40, 0, 0, 0, 0, 0, 60, 66, 153, 161, 161, 153, 66, 60,
   1, 3, 7, 15, 31, 63, 127, 255,           // Stripe, #128
   128, 128, 128, 128, 128, 128, 128, 128,  // Left-side bar, #129
   128, 128, 128, 128, 128, 128, 128, 255,  // left-side corner, #130
   0, 0, 0, 0, 0, 0, 0, 255,                // bottom, #131
   1, 1, 1, 1, 1, 1, 1, 255,                // Right-side corner, #132
   1, 1, 1, 1, 1, 1, 1, 1);                 // Right-side bar, #133

Var

  // Global vars -
  // System data pointers

  DIBHandle: Pointer;                       // Pointer to a graphics surface
  SoundHandle: Pointer;                     // Pointer to a buffer which will contain PCM sound data
  SoundSize: Integer;                       // The number of bytes of sound in the buffer
  EARStatus: Boolean;                       // The state of the EAR port
  LastEarStatus: Boolean;                   // Simple antialiasing is used with this
  SoundPos: pByte;                          // The position in the buffer is marked by this pointer

  KeyClick48k,
  KeyClick128k,
  KeyClick128kOK: Array of Byte;            // Samples of keyclicks, 44.1khz, 8bit, mono.

  BufferingSample: Boolean;                 // Buffering a keyclick sample?
  ClickBufferPtr: pByte;                    // When buffering a keyclick sound, points to the next sample
  ClickBufferLen: LongInt;                  // The length of the keyclick buffer
  ClickBufferPos: LongInt;                  // How many samples we've buffered

  Current_Loader,                           // Info about the current loader's type
  Current_Header,
  Current_Data: TLoaderInfo;
  Current_Environment: TEnvironmentInfo;    // Info about the environment - hardware, programming type etc
  Header_Data: Array of Byte;               // Binary dump of the header
  Screen_Data: Array[0..6911] of Byte;      // Binary dump of the screen data - .scr format
  Display: Array[0..6911] of Byte;          // An array for the screen to be loaded /to/. Used to make the display.
  Data_Ptr: pByte;                          // Pointer to data to be loaded - points to either header or screen data.
  AttrAddresses: Array[0..6144] Of Integer; // Address of the attribute byte for each byte in the display
  ScreenAddresses: Array[0..191] of Integer;// Address of the first byte of each row
  ScreenOffsets: Array[0..6143] of Integer; // Coordinate of the row for each byte in the display file - add the X yourself, it's easy.
  TsPerFrame: Integer;                      // 48k and 128k models have different speed CPUs.
  Max_Memory: Integer;                      // The amount of available memory - 32768 for a 16k machine, 65535 for a 48k/128k/+3 model.
  OkMessage: String;                        // Displayed at the end of the loops
  ErrorR: String;                           // R Tape Loading Error message.
  BREAKMessage: String;                     // The BREAK Message for when the screensaver is terminated during a load.
  TapeWobble: Integer;                      // Tape wobble factor
  TapeHiss: Integer;                        // Amount of Hiss to apply, if user wants us to.
  TapeAngle: Integer;                       // The amount of wobble currently employed
  TapeWobbleFactor: Integer;                // The computed amount of wobble.
  ChunteyDisrupted: Boolean;                // Has the chuntey field been disrupted?
  WillDisruptChuntey: Boolean;              // Will your mum enter the room at some point?
  ChunteyPosition: Integer;                 // The point in the data stream that the chuntey will be violated
  LastScreen_Disrupted: Boolean;            // Used to restart the programmer if Chuntey was disrupted
  ChunteyType: TChunteyType;                // Will we skip an edge or will we gain an extra one?
  Random48k: Boolean;                       // Are we selecting 48k modes at random currently?
  PilotFrameCount: Integer;

  // Info about what's going on currently

  InProgress: Boolean;                      // This is TRUE while a screen is being loaded.
  Stage: TLoaderStage;                      // Which stage of the loading process we're at
  Last_Stage: TLoaderStage;                 // Used to determine if the screensaver can be terminated with a BREAK message
  DataStage: TDataStage;                    // Indicates what part of the data is being loaded (sync1, sync2, data1, Data2)
  DataType: TDataType;                      // Loading header or screen data?
  FlashState: Byte;                         // Is FLASH currently on or off?
  TStateCount: Integer;                     // Elapsed TStates - wraps at 69888, so has to be global
  FrameCount: Integer;                      // Elapsed frames
  FrameTarget: Integer;                     // The time that the next "event" occurs
  PreHeaderStage: Byte;                     // Takes two frames to change the border in the Pre-header stage
  PulseNumber: Byte;                        // Which border colour are we currently using?
  DataPosition_Byte: Integer;               // Points to the byte currently being "loaded"
  DataPosition_Bit: Byte;                   // And similarly points to the current bit in the current byte
  CurrentBorder: Byte;                      // The current border colour for static displays
  PilotCount: Integer;                      // Number of pulses done for the current Pilot tone
  Display_Name: String;                     // The filename that appears after "Bytes: "
  Screen_Number: Integer;                   // How many screens have we done?
  Loop_Target: Integer;                     // Indicates how many loops we're to do
  Pilot_Loop_Count: Integer;                // How many loops of the tone/click we've done for clicking pilot tones
  Pilot_Click_Count: Integer;               // How many pulses we've done of the click period
  LeftOverTStates: Integer;                 // Used in sound output to prevent sample shortening

  // Reset parameter - stuff that's happening during a reset sequence

  ResetAddress: Integer;                    // The address being filled with "2" or cleared
  ResetStage: TResetStage;                  // Which stage of the reset process is currently excuting
  MenuStage: TMenuStage;                    // When drawing the 128k menus, which part of the drawing process we're at

  // Programmer - what's happening during the ghost-programmer stage

  ProgramStage: TProgramStage;              // The section we're in
  ProgramX: Integer;                        // Current X coordinate of the commandline
  ProgramPtr: Integer;                      // Current portion of the command line
  ProgramLineCount: Integer;                // Number of lines that have been used in the command line
  ProgramIndex: Integer;                    // Used in the programmer to count frames etc
  Commandline: Array of String;             // A copy of the command line
  CommandLineLen: Integer;                  // Number of elements in the command line
  LISTLine: String;                         // The lines to be auto-LISTed
  LISTPosX, LISTPosY: Integer;              // The current position of the character being output in an auto-LIST operation
  LISTIndex: Integer;                       // The current character in the LISTline being drawn
  Program128kImage: Array[0..671] of Byte;  // Used in the "programmer" sections of the 128k models - an image of the program as it appears onscreen.
  CommandLine128k: String;                  // The line being typed in 128k mode
  ScreenATLine: Integer;                    // Position that the "Bytes: XXXX" appears vertically
  ListMax: Integer;                         // Number of lines in a 128k program currently
  LineEntered: Boolean;                     // Used to determine if the 128k "Ok" beep is needed after a 128 BASIC screen clear
  GOTOLine: Integer;                        // The line number that program execution resumes at after an error R.
  LOADLine, LOADStatement: Integer;         // The line/Statement that caused Error R if it occurs.
  RUNEntered: Boolean;                      // Last command of the program was "RUN"?, if so signal a CLS.

// Procedure and function declarations

Procedure InitScreenSaver(DIBPointer, SoundPointer: Pointer; Environment: pEnvironmentInfo);
Procedure NewLoad(Filename: String; Header_Info, Data_Info: pLoaderInfo; CLS: Boolean);
Procedure SetUpProgrammer;
Procedure AddCommands(Commands: Array of String);
Procedure BuildTables;
Function  Frame: Boolean;
Procedure DisruptChuntey;
Procedure BufferSample(SampleType: Integer);
Procedure SoundOut(ElapsedTStates: Integer);
procedure CreateKeyClicks;
Function  Do_Reset: Boolean;
Function  Do_Programmer: Boolean;
Procedure DrawDisplay(BorderColour: Byte; StartTs, EndTs: Integer);
Procedure TStatesToScreen(TStates: Integer; Var ScrPos: TPoint);
Procedure MakeHeader(Filename: String);
Procedure DrawText(Text: String; Attr: Byte; X, Y: Integer);
Procedure ScrollUp(Ink: Byte);
Procedure ScrollScreen;
Procedure TerminateSaver(Immediate: Boolean);

// Procedures which replace those in sysutils.pas and windows.pas

Procedure CopyMem(Dst, Src: Pointer; Len: LongInt);
Function  GetFilename(Name: String): String;
Function  Lower(Text: String): String;
Function  IntToString(Value: Integer): String;

implementation

Procedure InitScreenSaver(DIBPointer, SoundPointer: Pointer; Environment: pEnvironmentInfo);
Begin

  // The environment specifies which hardware to use, and other screensaver options.

  CopyMem(@Current_Environment.HardwareModel, @Environment^.HardWareModel, SizeOf(TEnvironmentInfo));

  // DIBPointer should point to the surface bytes of a bitmap that has been set up
  // as a 352x296x8 image, with the Spectrum Palette loaded into the first 16 colour
  // indices.

  BuildTables;
  DIBHandle := DIBPointer;
  FillChar(Display[0], 6144, 0);
  FillChar(Display[6144], 768, Current_Environment.CLSAttr);

  // SoundPointer should point to a 1kb buffer for 8bit mono PCM output.

  SoundHandle := SoundPointer;
  SoundSize := 0;
  EarStatus := False;
  CreateKeyClicks;

  // Set the speed of the CPU and the memory available based on the hardware model.
  // Note that TsPerFrame does not change to 69888 when in 48k mode on 128k/+3 based hardware

  If Current_Environment.HardwareModel in [h16k, h48k] Then Begin
     TsPerFrame := 69888;
     If Current_Environment.HardwareModel = h16k Then
        Max_Memory := 32768
     Else
        Max_Memory := 65535;
  End Else Begin
     TsPerFrame := 70908;
     Max_Memory := 65535;
  End;

  // Set up the programmer, if necessary.

  LastScreen_Disrupted := False;
  SetupProgrammer;

  Screen_Number := -1;
  FrameCount := 0;
  FlashState := 0;

End;

Procedure NewLoad(Filename: String; Header_Info, Data_Info: pLoaderInfo; CLS: Boolean);
Var
  ChunteyChance: Integer;
  ModifyTs, Idx: Integer;
  DoReset: Boolean;
Begin

  // Set up for a new screen. Header_Data and Screen_Data should be pre-filled with the correct data.
  // The procedure CreateHeader() can be used to generate a header for ROM load styles.

  CopyMem(@Current_Header.Pilot_Border_1, @Header_Info^.Pilot_Border_1, SizeOf(TLoaderInfo));
  CopyMem(@Current_Data.Pilot_Border_1, @Data_Info^.Pilot_Border_1, SizeOf(TLoaderInfo));

  // Adding a random amount to the pilot tone length alters the behaviour of the pilot tone stripes.
  // a small effect, but adds to the authenticity.

  ModifyTs := Random(20) - 10;
  Inc(Current_Header.Pilot_Tone_Length, ModifyTs);
  Inc(Current_Data.Pilot_Tone_Length, ModifyTs);

  // Set up the screen for a new loader

  If CLS or Current_Environment.AttrsOnly Then Begin

     // If we are to clear the screen before loading, then blank to non-bright white
     // and fill the current display "memory" with a white screen (ATTR=56).

     FillChar(Display[0], 6144, 0);
     FillChar(Display[6144], 768, Current_Environment.CLSAttr);

  End;

  // Set the variables for looping and screen clearing. These are just counters.
  // A "loop" consists of one run through - if the user elects to CLS every 3 screens, and loop twice
  // then you'll get 6 screens.

  If Current_Environment.Looped > 0 Then Begin
     If Current_Environment.CLS > 0 Then
        Loop_Target := (Current_Environment.Looped +1) * Current_Environment.CLS
     Else
        Loop_Target := Current_Environment.Looped +1;
  End Else
     Loop_Target := 0;

  // Is a reset necessary? Only if we're not in slideshow mode, and this isn't in the middle of a loop.

  If (Current_Environment.Programmer <> pgmNone) And (Screen_Number = -1) Then Begin
     Stage := lsReset;
     Screen_Number := Loop_Target -1;
  End Else
     If Current_Environment.Programmer <> pgmNone Then
        Stage := lsProgram
     Else
        Stage := lsPostProgram;

  FrameCount := FrameCount And 15;

  // Set up pointers and more counters etc.
  // We start with a counter, and one second's worth of delay.
  // Oh yes, with a white border too :)

  DataType := dtHeader;
  FrameTarget := 50;
  PulseNumber := 0;
  ResetAddress := Max_Memory;
  CurrentBorder := Current_Header.FinalBorder;

  MakeHeader(Current_Environment.HeaderName);

  DrawDisplay(CurrentBorder, 0, 69888);

  InProgress := True;
  Inc(Screen_Number);

  If Random48k Then Current_Environment.Mode48k := T48kMode(Random(4)+1);

  // If the reset system is set to random, then test if we're going to reset right now.

  If Current_Environment.Programmer <> pgmNone Then
     If Current_Environment.ResetMethod >= 0 Then Begin

        Case Current_Environment.ResetMethod of

           -1: DoReset := False;
            0: DoReset := Random(50) > 25;

        Else

           DoReset := (Screen_Number Mod Current_Environment.ResetMethod) = 0;

        End;

        If DoReset Then Begin

           SetLength(CommandLine, 0);

           If Current_Environment.RandomHWAfterReset Then Begin

              // If the user selected to use a random hardware model after a reset, then
              // select one now. At random, natch.

              Idx := Random(5);
              Case Idx of
                 0: Current_Environment.HardwareModel := h16k;
                 1: Current_Environment.HardwareModel := h48k;
                 2: Current_Environment.HardwareModel := h128k;
                 3: Current_Environment.HardwareModel := hPlus2;
                 4: Current_Environment.HardwareModel := hPlus2a;
                 5: Current_Environment.HardwareModel := hPlus3;
              End;
              If Current_Environment.HardwareModel in [h16k, h48k] Then Begin
                 TsPerFrame := 69888;
                 If Current_Environment.HardwareModel = h16k Then
                    Max_Memory := 32768
                 Else
                    Max_Memory := 65535;
              End Else Begin
                 TsPerFrame := 70908;
                 Max_Memory := 65535;
              End;
           End;

           // Finally, set the screensaver's stage to the first part of a reset sequence.

           Case Current_Environment.HardwareModel of
              h128kUSR0: Current_Environment.HardwareModel := h128k;
              hPlus2USR0: Current_Environment.HardwareModel := hPlus2;
              hPlus2aUSR0: Current_Environment.HardwareModel := hPlus2a;
              hPlus3USR0: Current_Environment.HardwareModel := hPlus3;
           End;

           If Current_Environment.HardwareModel in [h16k, h48k] Then
              ProgramStage := ps48kBegin
           Else
              ProgramStage := ps128kBegin;
           Stage := lsReset;
           ResetStage := rsStart;
           Screen_Number := Loop_Target;

           // A reset, and random hardware selection, will need a new Program or
           // Direct command to be set up.

           SetUpProgrammer;

        End;

     End;

  // Initialise the tape wobble vars here. The Wobble will be different for every tape (or screen!).

  TapeAngle := 0;
  TapeWobbleFactor := Random(20)+5;

  // And make sure any previous chuntey disruptions don't affect this load.

  ChunteyDisrupted := False;
  WillDisruptChuntey := False;

  // Set up paramaters to trigger a chuntey disruption later in the load.
  // We have a chance that Chuntey is disrupted during the data loading phase,
  // and R Tape Loading Error will result.

  If Current_Environment.Chuntey Then Begin
     ChunteyChance := 10;
     If Current_Environment.TapeWobble Then
        Inc(ChunteyChance, 10);
     If Current_Environment.TapeHiss Then
        Inc(ChunteyChance, 10);
     If Random(1000) < ChunteyChance Then Begin
        WillDisruptChuntey := True;
        ChunteyPosition := Random(Current_Data.Data_Length);
     End;
  End;

  BufferingSample := False;

End;

Function Frame: Boolean;
Var
  LastTs: Integer;
  ChangeAtTStates, Idx: Integer;
  LoadingByte: LongInt;
  Ink: Byte;
  Update: Boolean;
  TempStr: String;
Begin

  // Output a frame of graphics, based on the Loader Stage.
  // When the data section has finished, set the InProgress var to False.
  // Result is True when graphics have been drawn and need updating.

  Result := False;
  Update := False;

  // Initialise this frame's buffer of sound samples.

  SoundPos := SoundHandle;
  FillChar(SoundHandle^, 1024, 0);
  SoundSize := 0;

  // Flashing attributes change state every 16 frames.

  FlashState := (FrameCount And 16) Shr 4;

  While TStateCount < TsPerFrame Do Begin

     // If preferred, set the Tape Wobble and Hiss variables to be added to tones later

     If (Current_Environment.TapeWobble) and (Stage > lsPostProgram) Then Begin
        Inc(TapeAngle, Round(Current_Loader.Pilot_Tone_Length / Current_Loader.Data_Zero_Length));
        If TapeAngle = 10000 Then Begin
           TapeAngle := 0;
           TapeWobbleFactor := Random(20)+5;
        End;
        TapeWobble := Round(TapeWobbleFactor*Sin((TapeAngle/27)*PI/180));
     End;

     // Tape hiss is a small random value that is added to the widths of the tape edges.

     If Current_Environment.TapeHiss Then Begin
        TapeHiss := Random(100)-50;
     End;

     Case Stage of

        lsReset:
           Begin

              // Reset the spectrum, based on options set in the environment record

              Update := True;
              If Not Do_Reset Then Begin
                 Stage := lsProgram;

                 // After a reset, clear out the 128k's program image so it doesn't get
                 // redrawn. This is a buffer that is used when a line has been entered, to paint
                 // the listing.

                 If Current_Environment.HardwareModel in [h128k, hPlus2, hPlus2a, hPlus3] Then
                    FillChar(Program128kImage[0], 672, 32);
              End;

           End;

        lsProgram:
           Begin

              If (Not LastScreen_Disrupted) And ((Screen_Number < Loop_Target) or ((Screen_Number > 0) and (Loop_Target = 0))) Then Begin

                 Stage := lsPostProgram;

              End Else Begin

                 // This executes the "ghost programmer" code, which simulates a user typing
                 // LOAD "" SCREEN$ and program loops etc.

                 Update := True;

                 If Not Do_Programmer Then Begin

                    // The programmer may have triggered a 48 BASIC option, thus setting a reset.
                    If Stage <> lsReset Then Begin

                       FrameCount := FrameCount And 15;
                       Screen_Number := 0;
                       LastScreen_Disrupted := False;
                       Stage := lsPostProgram;

                    End;

                 End;

              End;

           End;

        lsPostProgram:
           Begin

              // Move the header data into the current loader info structure for use by this proc.

              If Current_Environment.DoHeader Then
                CopyMem(@Current_Loader.Pilot_Border_1, @Current_Header.Pilot_Border_1, SizeOf(TLoaderInfo))
              Else Begin
                DataType := dtData;
                CopyMem(@Current_Loader.Pilot_Border_1, @Current_Data.Pilot_Border_1, SizeOf(TLoaderInfo));
              End;

              Stage := lsPreLoad;

              If RunEntered Then Begin
                 RUNEntered := False;
                 FillChar(Display[0], 6144, 0);
                 FillChar(Display[6144], 768, 56);
                 ScreenATLine := 0;
              End;

           End;

        lsPreLoad:
           Begin

              // A delay in which absolutely nothing happens - allows the user to appreciate the screen after it's loaded.
              // Simulates the user delaying pressing PLAY on the tape for a second or two.

              If FrameCount > Current_Loader.PreLoad_Delay Then Begin

                 Stage := lsPrePilot;
                 PreHeaderStage := 0;

                 // Clear the screen if the params are right

                 If Current_Environment.CLS <> 0 Then
                    If Screen_Number Mod Current_Environment.CLS = 0 Then Begin
                       FillChar(Display[0], 6144, 0);
                       FillChar(Display[6144], 768, 56);
                       ScreenATLine := 0;
                    End;

              End;

              TStateCount := TsPerFrame;
              DrawDisplay(CurrentBorder, 0, TsPerFrame);
              Result := True;

           End;

        lsPrePilot:
           Begin

              // In the pre-header delay, the border flips between pilot1 and pilot2 colours
              // roughly once per second - minus a small random amount. Pilot tones play for the final 1 second.

              If Current_Loader.PreHeader_Delay = 0 Then Begin

                Stage := lsPilot;
                PilotCount := 0;
                Pilot_Loop_Count := Current_Loader.Pilot_Loops;
                Pilot_Click_Count := Current_Loader.Pilot_Click_Repeats;
                PilotFrameCount := 0;
                Case PulseNumber of
                   0: DrawDisplay(Current_Loader.Pilot_Border_1, 0, TsPerFrame);
                   1: DrawDisplay(Current_Loader.Pilot_Border_2, 0, TsPerFrame);
                End;

              End Else

                If FrameCount > FrameTarget Then Begin

                   // Finished?

                   If FrameCount > Current_Loader.PreHeader_Delay + Current_Loader.PreLoad_Delay Then Begin

                      Stage := lsPilot;
                      PilotCount := 0;
                      Pilot_Loop_Count := Current_Loader.Pilot_Loops;
                      Pilot_Click_Count := Current_Loader.Pilot_Click_Repeats;
                      PilotFrameCount := 50;
                      Case PulseNumber of
                         0: DrawDisplay(Current_Loader.Pilot_Border_1, 0, TsPerFrame);
                         1: DrawDisplay(Current_Loader.Pilot_Border_2, 0, TsPerFrame);
                      End;

                   End Else Begin

                      // If we're at Stage 0 of the Pre-Header section, then change the border at a random TState count.

                      If PreHeaderStage = 0 Then Begin

                         ChangeAtTStates := Random(TsPerFrame);

                         Case PulseNumber of

                            0: Begin
                                  DrawDisplay(Current_Loader.Pilot_Border_2, 0, ChangeAtTStates);
                                  DrawDisplay(Current_Loader.Pilot_Border_1, ChangeAtTStates, TsPerFrame);
                               End;

                            1: Begin
                                  DrawDisplay(Current_Loader.Pilot_Border_1, 0, ChangeAtTStates);
                                  DrawDisplay(Current_Loader.Pilot_Border_2, ChangeAtTStates, TsPerFrame);
                               End;

                         End;

                         FrameTarget := FrameCount +1;
                         PreHeaderStage := 1;
                         TStateCount := TsPerFrame;
                         Result := True;

                      End Else Begin

                         // In Stage 1, Clear the whole border.

                         Case PulseNumber of

                            0: DrawDisplay(Current_Loader.Pilot_Border_1, 0, TsPerFrame);
                            1: DrawDisplay(Current_Loader.Pilot_Border_2, 0, TsPerFrame);

                         End;

                         // Flip the pulse counter, and set up for the next
                         // border colour change.

                         PulseNumber := 1 - PulseNumber;
                         FrameTarget := FrameCount + 50 + (Random(20) - 10);
                         TStateCount := TsPerFrame;
                         Result := True;

                      End;

                   End;

                End Else Begin

                   // Not done enough frames yet - set TStateCount to the end of the frame,
                   // causing this frame to finish.

                   TStateCount := TsPerFrame;
                   DrawDisplay(CurrentBorder, 0, TsPerFrame);
                   Result := True;

                End;

           End;

        lsPilot:
           Begin

              // Draw the pilot tones. Again, flip between pilot1 and pilot2 colours
              // spaced apart by the TStates given in the info block. For clicking pilots,
              // there is a pilot tone followed by a number of pulses that make up the
              // "click".

              // Do this for the pilot count

              Result := True;

              If Pilot_Loop_Count > 0 Then Begin

                 If PilotCount < Current_Loader.Pilot_Repeats Then Begin

                    // Store the current TStates count - this will be where we draw *from*

                    LastTs := TStateCount;

                    // And draw *to* the width of a pulse. Should be about 8 or 9 lines.

                    Inc(TStateCount, Current_loader.Pilot_Tone_Length + TapeWobble + TapeHiss);

                    If PilotFrameCount = 0 Then Begin
                       Case PulseNumber of

                          0: DrawDisplay(Current_Loader.Pilot_Border_1, LastTs, TStateCount);
                          1: DrawDisplay(Current_Loader.Pilot_Border_2, LastTs, TStateCount);

                       End;
                    End Else
                       DrawDisplay(CurrentBorder, LastTs, TStateCount);

                    // Flip the pulse value, and hence the border colour. Increment the
                    // pilot count on each pulse change.

                    PulseNumber := 1 - PulseNumber;
                    EarStatus := Not EarStatus;
                    SoundOut(Current_Loader.Pilot_Tone_Length + TapeWobble + TapeHiss);
                    Inc(PilotCount);

                    If PilotCount = Current_Loader.Pilot_Repeats Then
                       Pilot_Click_Count := Current_Loader.Pilot_Click_Repeats;

                 End Else Begin

                    // Do the "click" section

                    If Pilot_Click_Count > 0 Then Begin

                       // Store the current TStates count - this will be where we draw *from*

                       LastTs := TStateCount;

                       // And draw *to* the width of a pulse. Should be about 8 or 9 lines.

                       Inc(TStateCount, Current_loader.Pilot_Click_Length + TapeWobble + TapeHiss);

                       If PilotFrameCount = 0 Then Begin
                          Case PulseNumber of

                             0: DrawDisplay(Current_Loader.Pilot_Border_1, LastTs, TStateCount);
                             1: DrawDisplay(Current_Loader.Pilot_Border_2, LastTs, TStateCount);

                          End;
                       End Else
                          DrawDisplay(CurrentBorder, LastTs, TStateCount);

                       // Flip the pulse value, and hence the border colour. Increment the
                       // pilot count on each pulse change.

                       PulseNumber := 1 - PulseNumber;
                       EarStatus := Not EarStatus;
                       SoundOut(Current_Loader.Pilot_Click_Length + TapeWobble + TapeHiss);
                       Dec(Pilot_Click_Count);

                    End Else Begin

                       Dec(Pilot_Loop_Count);
                       PilotCount := 0;

                    End;

                 End;

              End Else Begin

                 // Done enough Pilot pulses - time for the sync pulses.

                 Stage := lsData;
                 ChunteyDisrupted := False;
                 DataStage := dsSync1;

              End;

           End;

        lsData:
           Begin

              Case DataStage of

                 // Which stage are we currently at?

                 dsSync1:
                    Begin

                       // Sync 1 - one flip of the pulse level

                       LastTs := TStateCount;
                       Inc(TStateCount, Current_Loader.Sync1_Length + TapeHiss);
                       DrawDisplay(Current_Loader.Data_Border_1, LastTs, TStateCount);
                       EarStatus := Not EarStatus;
                       SoundOut(Current_Loader.Sync1_Length);
                       DataStage := dsSync2;

                    End;

                 dsSync2:
                    Begin

                       // Same for Sync2

                       LastTs := TStateCount;
                       Inc(TStateCount, Current_Loader.Sync2_Length + TapeHiss);
                       DrawDisplay(Current_Loader.Data_Border_2, LastTs, TStateCount);
                       EarStatus := Not EarStatus;
                       SoundOut(Current_Loader.Sync2_Length);

                       // Set up for the first byte of the coming data

                       DataStage := dsData1;
                       DataPosition_Byte := Current_Environment.StartAddress;
                       DataPosition_Bit := 128;

                       If DataType = dtHeader Then
                          Data_Ptr := @Header_Data[0]
                       Else
                          Data_Ptr := @Screen_Data[Current_Environment.StartAddress];

                    End;

                 dsData1:
                    Begin

                       // Load the actual Data. Uses the Data_Ptr pointer to access the array -
                       // This could be the header, or the screen data. Two copies of this section handle
                       // the pulse flips (2 of) for each bit.

                       LastTs := TStateCount;
                       LoadingByte := Data_Ptr^;

                       If LoadingByte And DataPosition_Bit = 0 Then
                          Inc(TStateCount, Current_Loader.Data_Zero_Length + TapeHiss)
                       Else
                          Inc(TStateCount, Current_Loader.Data_One_Length + TapeHiss);

                       DrawDisplay(Current_Loader.Data_Border_1, LastTs, TStateCount);
                       EarStatus := Not EarStatus;
                       SoundOut(TStateCount - LastTs);
                       DataStage := dsData2;

                    End;

                 dsData2:
                    Begin

                       // This produces the mirrored level-flip which each bit needs.
                       // Also has extra handling for setting up the next bit/byte.

                       LastTs := TStateCount;
                       LoadingByte := Data_Ptr^;
                       If WillDisruptChuntey Then
                          If DataPosition_Byte >= ChunteyPosition Then
                             DisruptChuntey;

                       // If we've had our chuntey disrupted, then skip a bit of data. Screws the display
                       // up no end, but looks great.
                       If ChunteyDisrupted Then
                          If ChunteyType = ctForward Then Begin
                             If DataPosition_Byte < Current_Loader.Data_Length -1 Then
                                LoadingByte := (LoadingByte Shl 1) or (Screen_Data[DataPosition_Byte +1] Shr 7)
                             Else
                                LoadingByte := LoadingByte Shl 1;
                          End Else Begin
                             If DataPosition_Byte > 0 Then
                                LoadingByte := (LoadingByte Shr 1) or (Screen_Data[DataPosition_Byte -1] And 1)
                             Else
                                LoadingByte := LoadingByte Shr 1;
                          End;

                       If LoadingByte And DataPosition_Bit = 0 Then
                          Inc(TStateCount, Current_Loader.Data_Zero_Length + TapeHiss)
                       Else
                          Inc(TStateCount, Current_Loader.Data_One_Length + TapeHiss);

                       DrawDisplay(Current_Loader.Data_Border_2, LastTs, TStateCount);
                       EarStatus := Not EarStatus;
                       SoundOut(TStateCount - LastTs);

                       // Set up for the next bit, or the next byte if this one has finished.

                       DataPosition_Bit := DataPosition_Bit Shr 1;

                       If DataPosition_Bit > 0 Then Begin

                          // Next Bit.

                          DataStage := dsData1;

                       End Else Begin

                          // Next Byte.

                          Inc(DataPosition_Byte);
                          DataPosition_Bit := 128;
                          If DataPosition_Byte <= Current_Environment.StartAddress + Current_Loader.Data_Length Then Begin

                             Inc(Data_Ptr);
                             DataStage := dsData1;
                             If DataType = dtData Then
                                Display[DataPosition_Byte -1] := LoadingByte And 255;

                          End Else Begin

                             // Finished this block of Data. If that was a header, then
                             // Set up to load the actual screen data and print the "Bytes: xxxx"
                             // To the screen.

                             If DataType = dtHeader Then Begin

                                Inc(ScreenATLine);
                                If ScreenATLine = 22 Then Begin
                                   Dec(ScreenATLine);
                                   ScrollScreen;
                                End;
                                DrawText('Bytes: '+Display_Name, Current_Environment.CLSAttr, 0, ScreenATLine);

                                DrawDisplay(7, 0, TsPerFrame);
                                Stage := lsPrePilot;
                                DataType := dtData;
                                FrameCount := FrameCount And 16;
                                FrameTarget := FrameCount + (Current_Loader.Data_Pause_Length Div 20) +50;
                                PilotFrameCount := 50;
                                CopyMem(@Current_Loader.Pilot_Border_1, @Current_Data.Pilot_Border_1, SizeOf(TLoaderInfo));
                                Update := True;
                                TStateCount := TsPerFrame;

                             End Else Begin

                                // Otherwise, enter the final pause - set the border to the colour dictated by
                                // the loader's specs, and display the error message if necessary.

                                DrawDisplay(Current_Loader.FinalBorder, 0, TsPerFrame);

                                // If we've been disrupted, maybe by our mother turning on the vaccuum cleaner or
                                // someone walking into the room, then generate Error R.

                                If ChunteyDisrupted And (Current_Environment.Programmer <> pgmNone) Then Begin

                                   DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 22);
                                   DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 23);
                                   If Current_Loader.FinalBorder < 4 Then Ink := 7 Else Ink := 0;
                                   Inc(Ink, Current_Loader.FinalBorder Shl 3);
                                   DrawText('R Tape loading error, '+IntToString(LOADLine)+':'+IntToString(LOADStatement), Ink, 0, 23);
                                   LastScreen_Disrupted := True;
                                   If Current_Environment.Programmer = pgmDirectCommand Then Begin
                                      // A Direct command has been lost, so needs to be entered again
                                      SetUpProgrammer;
                                      If Current_Environment.HardwareModel in [h128k, hPlus2, hPlus2a, hPlus3] Then Begin
                                         ProgramStage := ps128kClear;
                                         ProgramX := 4;
                                         ProgramPtr :=0;
                                      End Else Begin
                                         ProgramStage := ps48kBegin;
                                      End;

                                   End Else Begin

                                      // But a program can be resumed with a simple GO TO statement.
                                      SetLength(CommandLine, 0);
                                      If Current_Environment.HardwareModel in [h16k, h48k, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0] Then Begin
                                         ProgramStage := ps48kBegin;
                                         AddCommands([#254, 'GO TO ']);
                                         TempStr := IntToString(GOTOLine);
                                         For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                      End Else Begin
                                         ProgramX := 4;
                                         ProgramPtr := 0;
                                         ProgramStage := ps128kClear;
                                         AddCommands([#254, 'goto ' + IntToString(GOTOLine)]);
                                      End;

                                   End;

                                End Else Begin

                                   // Otherwise, this screen is done, and we need to set up for the next one.

                                   If (Current_Environment.Programmer <> pgmNone) And (Screen_Number = Loop_Target -1) Then Begin
                                      DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 22);
                                      DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 23);
                                      If Current_Loader.FinalBorder < 4 Then Ink := 7 Else Ink := 0;
                                      Inc(Ink, Current_Loader.FinalBorder Shl 3);
                                      DrawText(OkMessage, Ink, 0, 23);
                                      SetLength(CommandLine, 0);
                                      If Current_Environment.Programmer = pgmDirectCommand Then Begin
                                         // As above, direct commands must be re-entered.
                                         SetUpProgrammer;
                                         If Current_Environment.HardwareModel in [h128k, hPlus2, hPlus2a, hPlus3] Then Begin
                                            ProgramStage := ps128kClear;
                                            ProgramX := 4;
                                            ProgramPtr := 0;
                                         End Else Begin
                                            ProgramStage := ps48kBegin;
                                         End;
                                      End Else Begin

                                         // And programs can just be RUN again when they have finished.
                                         If Current_Environment.HardwareModel in [h16k, h48k, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0] Then Begin
                                            ProgramStage := ps48kBegin;
                                            AddCommands([#254, 'RUN ']);
                                            RUNEntered := True;
                                         End Else Begin
                                            ProgramX := 4;
                                            ProgramPtr := 0;
                                            ProgramStage := ps128kClear;
                                            AddCommands([#254, 'run']);
                                            RUNEntered := True;
                                         End;

                                      End;
                                   End;
                                End;

                                // Update the display and set the screensaver to its' final stage.

                                DrawDisplay(Current_Loader.FinalBorder, TStateCount, TsPerFrame);
                                Stage := lsFinish;
                                FrameCount := FrameCount And 15;
                                FrameTarget := FrameCount + (Round(Current_Environment.PauseLen * 50));
                                TStateCount := TsPerFrame;
                                Update := True;

                             End;

                          End;

                       End;

                    End;

              End;

              Result := True;

           End;

     lsFinish:

           Begin

              // The final pause after the data.

              TStateCount := TsPerFrame;
              If FrameCount >= FrameTarget Then Begin

                 // Signal finished.

                 InProgress := False;

              End Else Begin

                 DrawDisplay(Current_Loader.FinalBorder, 0, TsPerFrame);
                 Result := True;

              End;

           End;

        lsQuit:
           Begin

              // Exits the emulator - uses a D BREAK if in the middle of a LOAD, else just quits.

              If Current_Environment.Programmer = pgmNone Then Begin
                 InProgress := False;
                 TStateCount := TsPerFrame;
                 Update := True;
              End Else
                 Case Last_Stage of
                    lsReset, lsProgram:
                       Begin
                          InProgress := False;
                          TStateCount := TsPerFrame;
                          Update := True;
                       End;
                    lsPreLoad, lsPostProgram, lsPrePilot, lsPilot, lsData, lsPause:
                       Begin
                          DrawDisplay(Current_Loader.FinalBorder, 0, TsPerFrame);
                          DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 22);
                          DrawText('                                ', Current_Loader.FinalBorder Shl 3, 0, 23);
                          If Current_Loader.FinalBorder < 4 Then Ink := 7 Else Ink := 0;
                          Inc(Ink, Current_Loader.FinalBorder Shl 3);
                          DrawText('D Break - CONT repeats, '+IntToString(LOADLine)+':'+IntToString(LOADStatement), Ink, 0, 23);
                          FrameTarget := FrameCount + 125;
                          TStateCount := TsPerFrame;
                          Update := True;
                          Stage := lsFinish;
                       End;
              End;

           End;

     Else

        Begin

           TStateCount := TsPerFrame;
           Result := False;

        End;

     End;

  End;

  // Some parts (notably the reset and programming sections) update the screen all in one go - do this now,
  // if desired.

  If Update Then Begin
     DrawDisplay(CurrentBorder, 0, TsPerFrame);
     SoundSize := 0;
     SoundPos := SoundHandle;
     SoundOut(TsPerFrame);
     Result := True;
  End;

  // The TState counter cannot just simply reset to 0 at the end of a frame, it must overflow/wrap.

  If TStateCount >= TsPerFrame Then
     Dec(TStateCount, TsPerFrame);

  // If no sound was made (SoundSize = 0) Then tell the calling prog that there was about a frame's worth
  // of samples made - makes a silence section.

  If SoundSize = 0 Then
     SoundSize := 44100 Div 50
  Else
     Dec(SoundSize);

  Inc(FrameCount);
  If PilotFrameCount > 0 Then Dec(PilotFrameCount);

End;

Procedure TerminateSaver(Immediate: Boolean);
Begin

  // Sets the screensaver to the "Quit" stage, which triggers
  // D BREAK if we're loading a screen at the time. We store the current stage so
  // we know if this was so.

  If Immediate Then Begin

     Stage := lsFinish;
     FrameTarget := FrameCount +1;
     InProgress := False;

  End Else Begin

     Last_Stage := Stage;
     Stage := lsQuit;

  End

End;

Procedure DisruptChuntey;
Begin

  // Interrupt the loading process.

  If Stage = lsData Then Begin
     ChunteyDisrupted := True;
     WillDisruptChuntey := False;
     If Random(100) >= 50 Then
        ChunteyType := ctForward
     Else
        ChunteyType := ctBackward;
  End;

End;

Procedure BufferSample(SampleType: Integer);
Begin

  // Sends a sample to the internal buffer - in this case,
  // it's the pre-recorded keyclick noises.

  Case SampleType of

     0: Begin // 48k KeyClick
           ClickBufferPtr := @KeyClick48k[0];
           ClickBufferLen := Length(KeyClick48k);
        End;
     1: Begin // 128k KeyClick
           ClickBufferPtr := @KeyClick128k[0];
           ClickBufferLen := Length(KeyClick128k);
        End;
     2: Begin // 128k OK Noise
           ClickBufferPtr := @KeyClick128kOk[0];
           ClickBufferLen := Length(KeyClick128kOk);
        End;

  End;

  BufferingSample := True;
  ClickBufferPos := 0;

End;

Procedure SoundOut(ElapsedTStates: Integer);
Var
  Sample, SampleHalf, SampleFull: Byte;
Begin

  // Send a sample or two out to the sound buffer. Uses a crude form of
  // waveform shaping, by halving the amplitude of the first sample after a
  // polarity change.

  SampleHalf := Round((128 * Current_Environment.Sound_Volume)/256);
  SampleFull := Round((256 * Current_Environment.Sound_Volume)/256);

  If LastEarStatus <> EarStatus Then
     Sample := SampleHalf
  Else
     If EarStatus Then
        Sample := SampleFull
     Else
        Sample := 0;

  // Left over TStates are those that didn't make it into the loop last time round.
  // by taking them into account, we maintain the correct sound pitch and also the
  // correct timings for synchronisation.

  Inc(ElapsedTStates, LeftoverTStates);

  While ElapsedTStates > 80 Do Begin

     // One sample every 80Ts (or thereabouts) at 44.1khz.

     If BufferingSample Then Begin
        // If a sample has been selected to be played, then buffer
        // data from that sample rather than from the simulated EAR bit.
        If ClickBufferPos < ClickBufferLen Then Begin
           pByte(SoundPos)^ := pByte(ClickBufferPtr)^;
           Inc(ClickBufferPtr);
           Inc(ClickBufferPos);
        End Else Begin
           BufferingSample := False;
        End;
     End;

     If Not BufferingSample Then
        // Otherwise, sample the current tape signal.
        If EarStatus Then Begin
           pByte(SoundPos)^ := Sample;
           Sample := SampleFull;
        End Else Begin
           pByte(SoundPos)^ := Sample;
           Sample := 0;
        End;

     LastEarStatus := EarStatus;

     Dec(ElapsedTStates, 80);

     // Don't buffer more than 1000 bytes of sample - there should be no need.

     If SoundSize < 1000 Then Begin
        Inc(SoundPos);
        Inc(SoundSize);
     End Else
        Exit;

  End;

  // And save any leftovers for the next run through this proc.

  LeftOverTStates := ElapsedTStates;

End;

procedure CreateKeyClicks;
var
  Ptr: pByte;
  idx, rpt, DataCount, SoundType: integer;
  SoundValue, SilenceValue: Byte;
begin

  // Creates sound samples of the 48k and 128k keyclick noises, and the
  // 128k "OK" beep. These are used later by the BufferSample procedure.

  ptr := nil;

  For SoundType := 0 To 2 Do Begin

     Case SoundType of

        {Calculate length of sound data and of file data}

        0: Begin
              DataCount := 300;
              SetLength(KeyClick48k, DataCount);
              ptr := @KeyClick48k[0];
           End;
        1: Begin
              DataCount := 300;
              SetLength(KeyClick128k, DataCount);
              ptr := @KeyClick128k[0];
           End;
        2: Begin
              DataCount := 4000;
              SetLength(KeyClick128kOk, DataCount);
              ptr := @KeyClick128kOk[0];
           End;

     End;

     {calculate and write out the tone signal}

     SoundValue := (255 * Current_Environment.Sound_Volume) Div 256;
     SilenceValue := 0;

     Case SoundType of
        0: Begin // 48k Keyclick
              For Idx := 0 To 12 Do Begin
                 Ptr^ := SoundValue;
                 Inc(ptr);
              End;
              For Idx := 13 To 299 Do Begin
                 Ptr^ := SilenceValue;
                 Inc(ptr);
              End;
           End;
        1: Begin // 128k Keyclick
              For Idx := 0 To 149 Do Begin
                 ptr^ := SoundValue;
                 Inc(ptr);
              End;
           End;
        2: Begin // 128k Ok
              For rpt := 0 To 49 Do Begin
                 For Idx := 0 To 39 Do Begin
                    ptr^ := SoundValue;
                    Inc(Ptr);
                 End;
                 For Idx := 0 To 39 Do Begin
                    Ptr^ := SilenceValue;
                    Inc(Ptr);
                 End;
              End;
           End;

     End;

  End;

End;

Function Do_Reset: Boolean;
Begin

  // Displays a reset-sequence for a given hardware model

  Result := True;
  CurrentBorder := 7;

  Case ResetStage of

     rsStart:
        Begin

           If FrameCount >= FrameTarget Then Begin

              If Current_Environment.HardwareModel in [h16k, h48k, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0] Then Begin
                 ResetAddress := Max_Memory;
                 ResetStage := rsFill2;
              End Else Begin
                 ResetAddress := 0;
                 ResetStage := rs128kClear;
              End;

           End;
           TStateCount := TsPerFrame;

        End;

     rsFill2:
        Begin

           // RAM is filled with bytes of value 2, with a white border
           // From Max_Memory downwards towards the end of the ROM.

           Inc(TStateCount, 32);

           If ResetAddress < 23296 Then
              Display[ResetAddress - 16384] := 2;

           If ResetAddress = 16384 Then
              ResetStage := rsClear
           Else
              Dec(ResetAddress);

        End;

     rsClear:
        Begin

           // RAM is now cleared to zeros from 16384 upwards to Max_Memory.
           // This is done by subtracting 1 from each address twice.

           Inc(TStateCount, 84);

           If ResetAddress < 23296 Then
              Display[ResetAddress - 16384] := 0;

           If ResetAddress = Max_Memory Then
              ResetStage := rsCLS;

           Inc(ResetAddress);

        End;

     rs128kClear:
        Begin

           // Clear the display. 21 TStates per byte.

           If ResetAddress < 6912 Then Begin

              Inc(TStateCount, 21);
              Display[ResetAddress] := 0;
              Inc(ResetAddress);

           End Else Begin

              ResetStage := rs128kMenu;
              FrameTarget := FrameCount + 30;
              TStateCount := TsPerFrame;
              MenuStage := msMessage1;

           End;

        End;

     rs128kMenu:
        Begin

           // The following sections build, one frame at a time, the 128k menus.
           // The can take many frames to complete.

           If FrameCount >= FrameTarget Then Begin

              Case MenuStage of

                 msMessage1:
                    Begin
                       FillChar(Display[6144], 768, 56);
                       Case Current_Environment.HardwareModel of
                          h128k:
                             DrawText(#127+' 19', 56, 0, 23);
                          hPlus2:
                             DrawText(#127+'198', 56, 0, 23);
                          hPlus2a, hPlus3:
                             DrawText(#127+'1982, 1986, 1987 A', 56, 0, 23);
                       End;
                       MenuStage := msMessage2;
                    End;

                 msMessage2:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#127+' 1986 Sinclair Research Ltd', 56, 0, 23);
                                FrameTarget := FrameCount + 2;
                                MenuStage := msMenuStrip;
                             End;
                          hPlus2:
                             Begin
                                DrawText(#127+'1986, '+#127+'1982 Amstrad Consumer', 56, 0, 23);
                                MenuStage := msMessage3;
                             End;
                          hPlus2a, hPlus3:
                             Begin
                                DrawText(#127+'1982, 1986, 1987 Amstrad Plc.', 56, 0, 23);
                                MenuStage := msMessage3;
                                FrameTarget := FrameCount + 23;
                             End;
                       End;
                    End;

                 msMessage3:
                    Begin
                       Case Current_Environment.HardwareModel of
                          hPlus2:
                             Begin
                                DrawText(#127+'1986, '+#127+'1982 Amstrad Consumer', 56, 0, 22);
                                DrawText('              Electronic', 56, 0, 23);
                             End;
                          hPlus2a:
                             Begin
                                DrawText(#127+'1982, 1986, 1987 Amstrad Plc.', 56, 0, 22);
                                DrawText('D                             ', 56, 0, 23);
                             End;
                          hPlus3:
                             Begin
                                DrawText(#127+'1982, 1986, 1987 Amstrad Plc.', 56, 0, 22);
                                DrawText('Drive                         ', 56, 0, 23);
                             End;
                       End;
                       MenuStage := msMessage4;
                    End;

                 msMessage4:
                    Begin
                       Case Current_Environment.HardwareModel of
                          hPlus2:
                             Begin
                                DrawText('              Electronics Plc', 56, 0, 23);
                             End;
                          hPlus2a:
                             Begin
                                DrawText('Drive M: available.', 56, 0, 23);
                                FrameTarget := FrameCount +2;
                             End;
                          hPlus3:
                             Begin
                                DrawText('Drives A:, B: and M: available.', 56, 0, 23);
                                FrameTarget := FrameCount +2;
                             End;
                       End;
                       MenuStage := msMenuStrip;
                    End;

                 msMenuStrip:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText('128     ', 71, 7, 7);
                                DrawText(#128, 66, 15, 7);
                                DrawText(#128, 86, 16, 7);
                                DrawText(#128, 116, 17, 7);
                             End;
                          hPlus2:
                             Begin
                                DrawText('128 ', 71, 7, 7);
                             End;
                          hPlus2a:
                             Begin
                                DrawText('128 +2A ', 71, 7, 7);
                                DrawText(#128, 66, 15, 7);
                                DrawText(#128, 86, 16, 7);
                                DrawText(#128, 116, 17, 7);
                             End;
                          hPlus3:
                             Begin
                                DrawText('128 +3 ', 71, 7, 7);
                             End;
                       End;
                       MenuStage := msOptions1;
                    End;

                 msOptions1:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#128, 101, 18, 7);
                                DrawText(#128, 104, 19, 7);
                                DrawText(' ', 0, 20, 7);
                                DrawText(' Tape Loader  ', 120, 7, 8);
                                DrawText(' 128 BA', 120, 7, 9);
                             End;
                          hPlus2:
                             Begin
                                DrawText('128     ', 71, 7, 7);
                                DrawText(#128, 66, 15, 7);
                                DrawText(#128, 86, 16, 7);
                                DrawText(#128, 116, 17, 7);
                                DrawText(#128, 101, 18, 7);
                                DrawText(#128, 104, 19, 7);
                                DrawText(' ', 0, 20, 7);
                                DrawText(' Tape Load', 120, 7, 8);
                             End;
                          hPlus2a:
                             Begin
                                DrawText(#128, 101, 18, 7);
                                DrawText(#128, 104, 19, 7);
                                DrawText(' ', 0, 20, 7);
                                DrawText(' Loader       ', 120, 7, 8);
                                DrawText(' +3 B', 120, 7, 9);
                             End;
                          hPlus3:
                             Begin
                                DrawText('128 +3  ', 71, 7, 7);
                                DrawText(#128, 66, 15, 7);
                                DrawText(#128, 86, 16, 7);
                                DrawText(#128, 116, 17, 7);
                                DrawText(#128, 101, 18, 7);
                                DrawText(#128, 104, 19, 7);
                                DrawText(' ', 0, 20, 7);
                                DrawText(' Loader     ', 120, 7, 8);
                             End;
                       End;
                       MenuStage := msOptions2;
                    End;

                 msOptions2:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText('SIC    ', 120, 14, 9);
                                DrawText(' Calculator   ', 120, 7, 10);
                                DrawText(' 48 BASI', 120, 7, 11);
                             End;
                          hPlus2:
                             Begin
                                DrawText(' Tape Loader  ', 120, 7, 8);
                                DrawText(' 128 BASIC    ', 120, 7, 9);
                                DrawText(' Calculator', 120, 7, 10);
                             End;
                          hPlus2a:
                             Begin
                                DrawText(' +3 BASIC     ', 120, 7, 9);
                                DrawText(' Calculator   ', 120, 7, 10);
                                DrawText(' 48', 120, 7, 11);
                             End;
                          hPlus3:
                             Begin
                                DrawText(' Loader       ', 120, 7, 8);
                                DrawText(' +3 BASIC     ', 120, 7, 9);
                                DrawText(' Calculator', 120, 7, 10);
                             End;
                       End;
                       MenuStage := msOptions3;
                    End;

                 msOptions3:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText('C     ', 120, 15, 11);
                                DrawText(' Tape Tester  ', 120, 7, 12);
                                DrawText('         ', 120, 7, 13);
                             End;
                          hPlus2:
                             Begin
                                DrawText(' Calculator   ', 120, 7, 10);
                                DrawText(' 48 BASIC     ', 120, 7, 11);
                                DrawText('            ', 120, 7, 12);
                             End;
                          hPlus2a:
                             Begin
                                DrawText(' 48 BASIC     ', 120, 7, 11);
                                DrawText('            ', 120, 7, 12);
                             End;
                          hPlus3:
                             Begin
                                DrawText(' Calculator   ', 120, 7, 10);
                                DrawText(' 48 BASIC     ', 120, 7, 11);
                                DrawText('         ', 120, 7, 12);
                             End;
                       End;
                       MenuStage := msLeftBorder;
                    End;

                 msLeftBorder:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#129, 120, 7, 8);
                                DrawText(#129, 120, 7, 9);
                                DrawText(#129, 120, 7, 10);
                                DrawText(#129, 120, 7, 11);
                                DrawText(#129, 120, 7, 12);
                                DrawText(#129+'             ', 120, 7, 13);
                             End;
                          hPlus2, hPlus2a, hPlus3:
                             Begin
                                DrawText(#129, 120, 7, 8);
                                DrawText(#129, 120, 7, 9);
                                DrawText(#129, 120, 7, 10);
                                DrawText(#129, 120, 7, 11);
                                DrawText(#130+'             ', 120, 7, 12);
                             End;
                       End;
                       MenuStage := MsBottom1;
                    End;

                 msBottom1:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#130+#131+#131+#131+#131+#131+#131, 120, 7, 13);
                             End;
                          hPlus2, hPlus2a, hPlus3:
                             Begin
                                DrawText(#130+#131+#131+#131+#131+#131+#131+#131+#131, 120, 7, 12);
                             End;
                       End;
                       MenuStage := msBottom2;
                    End;

                 msBottom2:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#130+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131, 120, 7, 13);
                             End;
                          hPlus2, hPlus2a, hPlus3:
                             Begin
                                DrawText(#130+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#131+#132, 120, 7, 12);
                             End;
                       End;
                       MenuStage := msRightBorder;
                    End;

                 msRightBorder:
                    Begin
                       Case Current_Environment.HardwareModel of
                          h128k:
                             Begin
                                DrawText(#133, 120, 20, 8);
                                DrawText(#133, 120, 20, 9);
                                DrawText(#133, 120, 20, 10);
                                DrawText(#133, 120, 20, 11);
                                DrawText(#133, 120, 20, 12);
                                DrawText(#132, 120, 20, 13);
                                MenuStage := msHighlight;
                             End;
                          hPlus2, hPlus2a, hPlus3:
                             Begin
                                DrawText(#133, 120, 20, 9);
                                DrawText(#133, 120, 20, 10);
                                DrawText(#133, 120, 20, 11);
                                DrawText(#132, 120, 20, 12);
                                Case Current_Environment.HardwareModel of
                                   hPlus2:
                                      DrawText(#129+'Tape Loader '+#133, 104, 7, 8);
                                   hPlus2a, hPlus3:
                                      DrawText(#129+'Loader      '+#133, 104, 7, 8);
                                End;
                                FrameTarget := FrameCount + 50;
                                ResetStage := rsPause;
                             End;
                       End;
                    End;

                 msHighlight:
                    Begin
                       // Now that the menu has been displayed, highlight the
                       // top item in bright cyan and black.
                       DrawText(#129+'Tape Loader '+#133, 104, 7, 8);
                       FrameTarget := FrameCount + 50;
                       ResetStage := rsPause;
                    End;

              End;

           End;
           TStateCount := TsPerFrame;

        End;

     rsCLS:
        Begin

           FillChar(Display[0], 6144, 0);
           FillChar(Display[6144], 768,56);
           TStateCount := TsPerFrame;
           ResetStage := rsMessage;

        End;

     rsMessage:
        Begin

           Case Current_Environment.HardwareModel of
              h16k, h48k, h128kUsr0:
                 DrawText(#127+' 1982 Sinclair Research Ltd', 56, 0, 23);
              hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0:
                 DrawText(#127+' 1982 Amstrad', 56, 0, 23);
           End;
           TStateCount := TsPerFrame;
           FrameTarget := FrameCount + 50;
           ResetStage := rsPause;

        End;

     rsPause:
        Begin

           If FrameCount > FrameTarget Then Begin

              // The Reset sequence has finished - signal by setting the result to
              // false. The calling proc should now continue with the next section of the
              // screensaver.

              Result := False;
              ResetStage := rsStart;

           End;
           TStateCount := TsPerFrame;

        End;

     End;

End;

Function Do_Programmer: Boolean;
Var
  Ink: Byte;
  Idx: Integer;
  Text: String;
Begin

  Result := True;
  If CurrentBorder < 4 Then Ink := 7 Else Ink := 0;
  Inc(Ink, CurrentBorder Shl 3);

  TStateCount := TsPerFrame;

  Case ProgramStage of

     ps48kBegin:
        Begin

           If FrameCount >= FrameTarget Then Begin

              // Clear the lower two lines, add a flashing "K" cursor.
              DrawText('                                ', Ink, 0, 23);
              DrawText('                                ', Ink, 0, 22);
              DrawText('K', Ink + 128, 0, 23);
              FrameTarget := FrameCount + 75;
              ProgramStage := ps48kCommand;
              ProgramX := 0;
              ProgramPtr := 0;
              ProgramLineCount := 2;

           End;

        End;

     ps48kCommand:
        Begin
           // Begin typing the commandline

           If FrameCount > FrameTarget Then Begin

              If ProgramPtr = Length(CommandLine) Then Begin
                 // Finished - clear the lower screen and exit.
                 Result := False;
                 If ProgramLineCount < 2 Then
                    ProgramLineCount := 2;
                 For Idx := 1 To ProgramLineCount Do
                    DrawText('                                ', Ink, 0, 23 - (Idx -1));
                 ProgramPtr := 0;
                 ScreenATLine := 1;
                 BufferSample(0);
                 Exit;
              End Else Begin
                 Text := CommandLine[ProgramPtr];
                 Inc(ProgramPtr);
              End;

              If Text[1] = #0 Then Begin
                 // #0 changes the cursor to "E" extend mode for a few frames.
                 DrawText('E', Ink+128, ProgramX, 23);
              End Else If Text[1] = #254 Then Begin
                 // #254 indicates that the next chunk will be a command line.
                 // Clear the lower screen.
                 If ProgramLineCount < 2 Then
                    ProgramLineCount := 2;
                 For Idx := 1 To ProgramLineCount Do
                    DrawText('                                ', Ink, 0, 23 - (Idx -1));
                 ProgramX := 0;
                 ProgramLineCount := 2;
              End Else If Text[1] = #255 Then Begin
                 // #255 indicates that the command line elements are program lines
                 // to be listed at the top of the screen.
                 BufferSample(0);
                 ProgramX := 0;
                 ProgramLineCount := 2;
                 ProgramStage := ps48kList;
              End Else Begin
                 BufferSample(0);
                 // Wrap the text around the lower screen. Scroll the lower screen up,
                 // and start drawing text at the lower left again.
                 If ProgramX + Length(Text) > 31 Then Begin
                    DrawText(Copy(Text, 1, 32 - ProgramX), Ink, ProgramX, 23);
                    ScrollUp(Ink);
                    Text := Copy(Text, (32 - ProgramX) +1, Length(Text));
                    DrawText(Text, Ink, 0, 23);
                    ProgramX := Length(Text);
                    DrawText('L', Ink + 128, ProgramX, 23);
                 End Else Begin
                    DrawText(Text, Ink, ProgramX, 23);
                    Inc(ProgramX, Length(Text));
                    If ProgramX = 32 Then Begin
                       ScrollUp(Ink);
                       ProgramX := 0;
                    End;
                    DrawText('L', Ink + 128, ProgramX, 23);
                 End;
              End;
              If (Text = #254) or (Text = #255) Then
                 // These "indicator" bytes don't do anything.
                 FrameTarget := FrameCount
              Else Begin
                 // Characters that are repeated are typed quickest.
                 If Text = CommandLine[ProgramPtr -1] Then
                    FrameTarget := FrameCount + Random(15) + 15
                 Else
                    FrameTarget := FrameCount + Random(25) + 15;
                 // And an ExtendedMode selection takes longer to perform.
                 If Text = #0 Then Inc(FrameTarget, 18);
              End;

           End;

        End;

     ps48kList:
        Begin

           // Use ProgramX as a counter - 0..2 are the CLS,
           // After that it counts LISTed program lines.

           Case ProgramX of

              0: Begin
                    // Clear half the screen
                    FillChar(Display[0], 3072, 0);
                    Inc(ProgramX);
                 End;

              1: Begin
                    // Clear the last half
                    FillChar(Display[3072], 3072, 0);
                    Inc(ProgramX);
                 End;

              2: Begin
                    // Clear the Attributes
                    FillChar(Display[6144], 768, 56);
                    LISTPosX := 0;
                    LISTPosY := 0;
                    Inc(ProgramX);
                 End;

              3..999:
                 Begin

                    // Now draw the lines. Draws roughly (not allowing for colour commands and keyword
                    // decoding) about 29 characters per frame.

                    If ProgramX = 3 Then Begin

                       // set up the LISTline var - one long list of characters to be outputted, separated
                       // by #13 characters

                       LISTLine := CommandLine[ProgramPtr];
                       Inc(ProgramPtr);
                       Inc(ProgramX);
                       LISTIndex := 1;

                    End Else Begin

                       // Draw the listing. 28 chars per frame.

                       For Idx := 0 To 28 Do Begin

                          If LISTIndex <= Length(LISTLine) Then Begin
                             If (LISTLine[LISTIndex] = #13) or (LISTPosX = 32) Then Begin
                                LISTPosX := 0;
                                Inc(LISTPosY);
                                If LISTLine[LISTIndex] = #13 Then
                                   Inc(LISTIndex);
                             End;
                             DrawText(LISTLine[LISTIndex], 56, LISTPosX, LISTPosY);
                             Inc(LISTPosX);
                             Inc(LISTIndex);
                          End Else Begin

                             // When done, return to the programmer for the next line.

                             ProgramStage := ps48kCommand;
                             FrameTarget := FrameCount + 30 + Random(30);
                             ProgramX := 0;
                             ProgramLineCount := 2;
                             DrawText('K', 184, 0, 23);
                             Exit;
                          End;

                       End;

                       Inc(ProgramX);

                    End;

                 End;

           End;

        End;

     ps128kBegin:
        Begin

           // The programmer chooses 128 BASIC (or +3 BASIC) from the menu, and presses ENTER,
           // which causes the screen to clear over 3 frames.

           If FrameCount >= FrameTarget Then Begin

              Case ProgramX of

                 0: Begin
                       // Choose the BASIC option
                       Case Current_Environment.HardwareModel of
                          h128k, hPlus2:
                             Text := #129+'Tape Loader '+#133;
                          hPlus2a, hPlus3:
                             Text := #129+'Loader      '+#133;
                       End;
                       DrawText(Text, 120, 7, 8);
                       Case Current_Environment.HardwareModel of
                          h128k, hPlus2:
                             Text := #129+'128 BASIC   '+#133;
                          hPlus2a, hPlus3:
                             Text := #129+'+3 BASIC    '+#133;
                       End;
                       DrawText(Text, 104, 7, 9);
                       Inc(ProgramX);
                       FrameTarget := FrameCount + 30 + Random(25);
                       BufferSample(1);
                    End;

                 1: Begin
                       // Clear half the screen
                       BufferSample(1);
                       FillChar(Display[0], 3072, 0);
                       Inc(ProgramX);
                    End;

                 2: Begin
                       // Clear the last half
                       FillChar(Display[3072], 3072, 0);
                       Inc(ProgramX);
                    End;

                 3: Begin
                       // Clear the Attributes
                       FillChar(Display[6144], 768, 56);
                       LISTPosX := 0;
                       LISTPosY := 0;
                       Inc(ProgramX);
                       ProgramStage := ps128kClear;
                       LineEntered := False;
                       ProgramLineCount := 0;
                    End;
              End;

           End;

        End;

     ps128kClear:
        Begin

           // The 128k models clear in a similar manner to the 48k LIST command - about 29 chars/frame,
           // but all spaces. First, draw the black bar "128 BASIC" (or "+3 BASIC") in the lower screen
           // over 2 frames.

           Case ProgramX Of

              4: Begin
                    // Draw an empty black bar
                    DrawText('                                ', 0, 0, 21);
                    // And clear the lower screen
                    DrawText('                                ', 56, 0, 22);
                    DrawText('                                ', 56, 0, 23);
                    Inc(ProgramX);
                 End;

              5: Begin
                    // Draw the BASIC Text and stripes
                    Case Current_Environment.HardwareModel of
                       h128k, hPlus2:
                          DrawText('128 BASIC                 ', 71, 0, 21);
                       hPlus2a, hPlus3:
                          DrawText('+3 BASIC                  ', 71, 0, 21);
                    End;
                    DrawText(#128, 66, 26, 21);
                    DrawText(#128, 86, 27, 21);
                    DrawText(#128, 116, 28, 21);
                    DrawText(#128, 101, 29, 21);
                    DrawText(#128, 104, 30, 21);
                    DrawText(' ', 0, 31, 21);
                    Inc(ProgramX);
                    ListPosX := 0;
                    ListPosY := 0;
                    ListMax := 0;
                 End;

              6: Begin

                    // Now "clear" the screen - which will also list the current program
                    // Draw 28 characters of display per frame.

                    If LineEntered Then Begin
                       BufferSample(2);
                       LineEntered := False;
                    End;

                    If ListPosY < 21 Then Begin

                       For Idx := 0 To 28 Do Begin

                          DrawText(Chr(Program128kImage[ListPosX + (ListPosY * 32)]), 56, ListPosX, ListPosY);
                          Inc(ListPosX);
                          If ListPosX = 32 Then Begin
                             ListPosX := 0;
                             Inc(ListPosY);
                             If ListPosY = 21 Then
                                Break;
                          End;

                       End;

                    End Else Begin

                       // And now return to the program entering stage, for the next line.

                       ProgramStage := ps128kCommand;
                       FrameTarget := FrameCount + 30 + Random(10);
                       ProgramX := 9999;
                       ListPosX := 0;
                       ListPosY := ProgramLineCount;
                       DrawText(' ', 249, 0, ProgramLineCount);
                       Exit;
                    End;

                 End;

           End;

        End;

     ps128kCommand:
        Begin

           // begin typing the commands in.

           If FrameCount > FrameTarget Then Begin

              If (ProgramX >= Length(CommandLine128k)) and (ProgramPtr = Length(CommandLine)) Then Begin
                 // Finished
                 ProgramStage := ps128kDone;
                 FrameTarget := FrameCount + Random(25) + 16;
                 BufferSample(1);
                 Exit;
              End Else
                 If ProgramX >= Length(CommandLine128k) Then Begin
                    CommandLine128k := CommandLine[ProgramPtr] + ' ';
                    Inc(ProgramPtr);
                 End;

              If CommandLine128k[1] = #254 Then Begin
                 // #254 means a direct command.
                 // Remove the #254 now, so the line can be processed
                 CommandLine128k := Copy(CommandLine128k, 2, Length(CommandLine128k));
                 ListPosX := 0;
                 ListPosY := ProgramLineCount;
                 ProgramX := 1;
              End Else If CommandLine128k[1] = #255 Then Begin
                 // #255 is text that forms the program already in memory.
                 // Remove the #255 now, so the line can be added to the list
                 CommandLine128k := Copy(CommandLine128k, 2, Length(CommandLine128k));
                 CommandLine128k := '  '+CommandLine[ProgramPtr];
                 Inc(ProgramPtr);
                 Idx := 1;
                 While Idx <= Length(CommandLine128k) Do Begin
                    Program128kImage[Idx -1 + (ProgramLineCount * 32)] := Ord(CommandLine128k[Idx]);
                    Inc(Idx);
                 End;
                 Inc(ProgramLineCount);
                 FrameTarget := FrameCount + 25;
                 ProgramStage := ps128kClear;
                 ProgramX := 6;
                 ListPosX := 0;
                 ListPosY := 0;
                 LineEntered := True;
              End Else Begin
                 // All other text characters are to be displayed as if typed.
                 // one char at a time!
                 DrawText(CommandLine128k[ProgramX], 56, ListPosX, ListPosY);
                 Inc(ProgramX);
                 Inc(ListPosX);
                 If ListPosX = 32 Then Begin
                    // 128k editor indents automatically at line wrap.
                    ListPosX := 5;
                    Inc(ListPosY);
                 End;
                 DrawText(' ', 249, ListPosX, ListPosY);
                 BufferSample(1);
              End;
              If (CommandLine128k = #254) or (CommandLine128k = #255) Then
                 // The command/listing prefixes take no time.
                 FrameTarget := FrameCount
              Else Begin
                 If (ProgramX > 1) And (CommandLine128k[ProgramX] = CommandLine128k[ProgramX -1]) Then
                    // double-letters take less time to type.
                    FrameTarget := FrameCount + Random(5) + 10
                 Else
                    If (ProgramX <= Length(CommandLine128k)) And (CommandLine128k[ProgramX] in [' ', '0'..'9', 'a'..'z', 'A'..'Z']) Then
                       // Alpha-numerics take less time...
                       FrameTarget := FrameCount + Random(10) +10
                    Else
                       // ...than symbols, which have to be shifted.
                       FrameTarget := FrameCount + Random(15) +30;
              End;

           End;

        End;

     ps128kDone:
        Begin

           // finished typing - if this was a Usr0 or SPECTRUM command, then set it up now.
           // Otherwise, get ready to run.

           If FrameCount >= FrameTarget Then Begin

              Result := False;

              Case Current_Environment.Mode48k of

                 mdUsr0:
                    Begin
                       // Set up for a reset into 48k mode - first set the hardware:

                       Case Current_Environment.HardwareModel of
                          h128k:   Current_Environment.HardwareModel := h128kUsr0;
                          hPlus2:  Current_Environment.HardwareModel := hPlus2Usr0;
                          hPlus2a: Current_Environment.HardwareModel := hPlus2aUsr0;
                          hPlus3:  Current_Environment.HardwareModel := hPlus3Usr0;
                       End;

                       // And set the system to head into a reset when this is done:

                       SetUpProgrammer;
                       Stage := lsReset;
                       ResetStage := rsStart;
                       FrameTarget := FrameCount + 30 + Random(25);
                       Result := False;

                    End;

                 mdSPECTRUM:
                    Begin
                       // Do not reset - display the correct error message (the +2a models show an interesting
                       // OK message!) and then set up for more typing.

                       // Set up for a change to 48k mode - first set the hardware:

                       Case Current_Environment.HardwareModel of
                          h128k:   Current_Environment.HardwareModel := h128kUsr0;
                          hPlus2:  Current_Environment.HardwareModel := hPlus2Usr0;
                          hPlus2a: Current_Environment.HardwareModel := hPlus2aUsr0;
                          hPlus3:  Current_Environment.HardwareModel := hPlus3Usr0;
                       End;

                       FillChar(Display[0], 6144, 0);
                       FillChar(Display[6144], 768, 56);

                       For Idx := 1 To 3 Do
                          DrawText('                                ', Ink, 0, 23 - (Idx -1));
                       DrawText(OkMessage, 56, 0, 23);
                       FrameTarget := FrameCount + 30 + Random(25);

                       SetUpProgrammer;

                       // Set the result to indicate some more programming.
                       Result := True;

                    End;

                 mdNone:
                    Begin
                       // A small delay to flash the cursor and look like the user is reaching for the ENTER key :)
                       ProgramPtr := 0;
                       FrameTarget := FrameCount + 30 + Random(25);
                       ProgramStage := ps128kRUN;
                       Result := True;
                    End;

              End;

           End;

        End;

     ps128kRUN:
        Begin
           // Now clear the cursor, the lowerscreen (including black "128 BASIC" bar) and beep one final time.
           BufferSample(1);
           ProgramPtr := 0;
           For Idx := 1 To 3 Do
              DrawText('                                ', Ink, 0, 23 - (Idx -1));
           DrawText(' ', 56, ListPosX, ListPosY);
           ScreenATLine := ListPosY +1;
           FrameTarget := FrameCount + 4;
           Result := False;
        End;

     ps128kTo48k:
        Begin

           // A special case - choose 48k Mode from the menu, and trigger a reset into a "usr0" hardware model
           // All other methods of getting into 48k mode involve 128/+3 BASIC and are handled by the above routines.

           If FrameCount >= FrameTarget Then Begin

              Case ProgramX of

                 0: Begin
                       // Highlight the BASIC option
                       BufferSample(1);
                       Case Current_Environment.HardwareModel of
                          h128k, hPlus2:
                             Text := #129+'Tape Loader '+#133;
                          hPlus2a, hPlus3:
                             Text := #129+'Loader      '+#133;
                       End;
                       DrawText(Text, 120, 7, 8);
                       Case Current_Environment.HardwareModel of
                          h128k, hPlus2:
                             Text := #129+'128 BASIC   '+#133;
                          hPlus2a, hPlus3:
                             Text := #129+'+3 BASIC    '+#133;
                       End;
                       DrawText(Text, 104, 7, 9);
                       Inc(ProgramX);
                       FrameTarget := FrameCount + 10 + Random(25);
                    End;

                 1: Begin
                       // Highlight the Calculator option
                       BufferSample(1);
                       Case Current_Environment.HardwareModel of
                          h128k, hPlus2:
                             Text := #129+'128 BASIC   '+#133;
                          hPlus2a, hPlus3:
                             Text := #129+'+3 BASIC    '+#133;
                       End;
                       DrawText(Text, 120, 7, 9);
                       DrawText(#129+'Calculator  '+#133, 104, 7, 10);
                       Inc(ProgramX);
                       FrameTarget := FrameCount + 10 + Random(25);
                    End;

                 2: Begin
                       // Highlight the 48 BASIC option
                       BufferSample(1);
                       DrawText(#129+'Calculator  '+#133, 120, 7, 10);
                       DrawText(#129+'48 BASIC    '+#133, 104, 7, 11);
                       Inc(ProgramX);
                       FrameTarget := FrameCount + 30 + Random(25);
                    End;

                 3: Begin
                       //Begin clearing the menu
                       DrawText('              ', 56, 7, 7);
                       DrawText('              ', 120, 7, 8);
                       Inc(ProgramX);
                       FrameTarget := FrameCount +1;
                    End;

                 4: Begin
                       // Clear the rest of the menu
                       DrawText('              ', 56, 7, 7);
                       DrawText('              ', 56, 7, 8);
                       DrawText('              ', 56, 7, 9);
                       DrawText('              ', 56, 7, 10);
                       DrawText('              ', 56, 7, 11);
                       DrawText('              ', 56, 7, 12);
                       DrawText('              ', 56, 7, 13);
                       Inc(ProgramX);
                       FrameTarget := FrameCount +1;
                    End;

                 5: Begin
                       // Now user presses ENTER.
                       // Set up for a reset into 48k mode - first set the hardware:

                       BufferSample(1);
                       Case Current_Environment.HardwareModel of
                          h128k:   Current_Environment.HardwareModel := h128kUsr0;
                          hPlus2:  Current_Environment.HardwareModel := hPlus2Usr0;
                          hPlus2a: Current_Environment.HardwareModel := hPlus2aUsr0;
                          hPlus3:  Current_Environment.HardwareModel := hPlus3Usr0;
                       End;

                       // And set the system to head into a reset when this is done:

                       FrameTarget := FrameCount + 1;
                       SetUpProgrammer;
                       Stage := lsReset;
                       ResetStage := rsStart;
                       Result := False;

                    End;

              End;

           End;

        End;

  End;

End;

// Setup routines for various states and stuff

Procedure BuildTables;
Var
  YPoint, XPoint,
  Address, Block,
  Row, Offset: Integer;
Begin

  // Various LUTs for quickly converting from coords to addresses and vice-versa
  // ScreenOffsets[] holds the Y-Coord for any byte in the display[] array, not attrs
  // AttrAddresses[] holds the offset of the attribute for any byte in Display[]
  // ScreenAddresses[] holds the address of the first byte of each line in the bitmap.

  For Address := 0 To 6143 Do Begin

     XPoint := Address And 31;
     Row := (Address And 224) Div 32;
     Offset := (Address And 1792) Div 256;
     Block := (Address And 6144) Div 2048;
     YPoint := Offset+Row*8+Block*64;
     ScreenOffsets[Address] := YPoint;
     AttrAddresses[Address] := 6144 + ((((YPoint) Div 8)*32)+XPoint);
     If Address Mod 32 = 0 Then ScreenAddresses[YPoint] := Address;

  End;

End;

Procedure SetUpProgrammer;
Var
  Idx: Integer;
  TempStr, LoadString128k, LoadStringTokens, PauseStr: String;
Begin

  // Set parameters for the "ghost programmer"

  // The +2a and +3 use the "t:" drive specification for tapes, the 128k/+2 does not.

  If Current_Environment.HardwareModel in [h128k, hplus2] Then Begin
     LoadStringTokens := 'LOAD ""SCREEN$';
     LoadString128k := 'load "" screen$';
  End Else Begin
     LoadStringTokens := 'LOAD "t:"SCREEN$';
     LoadString128k := 'load "t:" screen$';
  End;

  LOADLine := 0;
  LOADStatement := 1;
  PauseStr := IntToString(Round(Current_Environment.PauseLen * 50));
  If Current_Environment.PauseLen = 0 Then
     PauseStr := '1';

  Case Current_Environment.Programmer of

     pgmDirectCommand:
        Begin

           RUNEntered := False;
           Case Current_Environment.HardwareModel of
              h16k, h48k, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0:
                 Begin

                    ProgramStage := ps48kBegin;
                    ProgramX := 0;
                    ProgramPtr := 0;
                    SetLength(CommandLine, 0);

                    If Current_Environment.Looped = 0 Then Begin
                       // Non-looped
                       If Current_Environment.CLS = 0 Then Begin
                          // Never CLS
                          AddCommands([#254, 'LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                          For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                          OkMessage := '0 Ok, 0:2';
                          LOADStatement := 1;
                       End Else
                          If Current_Environment.CLS = 1 Then Begin
                             // CLS every screen
                             AddCommands([#254, 'CLS ', ':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             OkMessage := '0 Ok, 0:3';
                             LOADStatement := 2;
                          End Else Begin
                             // CLS every n screens
                             AddCommands([#254, 'CLS ', ':', ' FOR ', 'f', '=', '1', ' TO ']);
                             TempStr := IntToString(Current_Environment.CLS);
                             For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                             AddCommands([':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([' NEXT ', 'f']);
                             OkMessage := '0 Ok, 0:5';
                             LOADStatement := 3;
                          End;
                    End Else Begin
                       // Looped.
                       If Current_Environment.Looped = -1 Then Begin
                          // Loop forever
                          If Current_Environment.CLS = 0 Then Begin
                             // Never CLS
                             AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ', '1', ':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':',
                                          ' LET ', 'f', '=', '0', ':', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([':', ' NEXT ', 'f']);
                             OkMessage := '0 Ok, 0:5';
                             LOADStatement := 2;
                          End Else
                             If Current_Environment.CLS = 1 Then Begin
                                // CLS every screen
                                AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ', '1', ':', ' CLS ', ':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([':', ' LET ', 'f', '=', '0', ':', ' NEXT ', 'f']);
                                OkMessage := '0 Ok, 0:6';
                                LOADStatement := 3;
                             End Else Begin
                                // CLS every n screens
                                AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ', '1', ':', ' CLS ', ':', ' FOR ', 'g', '=', '1', ' TO ']);
                                TempStr := IntToString(Current_Environment.CLS);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([':', ' NEXT ', 'g', ':', ' LET ', 'f', '=', '0', ':', ' NEXT ', 'f']);
                                OkMessage := '0 Ok, 0:8';
                                LOADStatement := 4;
                             End;
                       End Else Begin
                          // Loop for n frames
                          If Current_Environment.CLS = 0 Then Begin
                             // Never CLS
                             AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ']);
                             TempStr := IntToString(Current_Environment.Looped);
                             For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                             AddCommands([':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([':', ' NEXT ', 'f']);
                             OkMessage := '0 Ok, 0:4';
                             LOADStatement := 2;
                          End Else
                             If Current_Environment.CLS = 1 Then Begin
                                // CLS every screen
                                AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ']);
                                TempStr := IntToString(Current_Environment.Looped);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([':', ' CLS ', ':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([':', ' NEXT ', 'f']);
                                OkMessage := '0 Ok, 0:5';
                                LOADStatement := 3;
                             End Else Begin
                                // CLS every n screens
                                AddCommands([#254, 'FOR ', 'f', '=', '0', ' TO ']);
                                TempStr := IntToString(Current_Environment.Looped);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([':', ' CLS ', ':', ' FOR ', 'g', '=', '1', ' TO ']);
                                TempStr := IntToString(Current_Environment.CLS);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([':', ' LOAD ', '"', '"', #0, 'SCREEN$ ', ':', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([':', ' NEXT ', 'g', ':', ' NEXT ', 'f']);
                                OkMessage := '0 Ok, 0:7';
                                LOADStatement := 4;
                             End;
                       End;
                    End;

                    CommandLineLen := High(CommandLine);

                 End;

              h128k, hPlus2, hPlus2a, hPlus3:
                 Begin
                    If Current_Environment.Mode48k = md48BASIC Then
                       ProgramStage := ps128kTo48k
                    Else
                       ProgramStage := ps128kBegin;
                    ProgramX := 0;
                    ProgramPtr := 0;
                    SetLength(CommandLine, 0);

                    If Current_Environment.Mode48k = mdUSR0 Then Begin

                       AddCommands([#254, 'usr0']);

                    End Else

                       If Current_Environment.Mode48k = mdSPECTRUM Then Begin

                          AddCommands([#254, 'spectrum']);
                          If Current_Environment.HardwareModel in [hPlus2a, hPlus3] Then
                             OkMessage := 'OUT 7I, 0:1'
                          Else
                             OkMessage := '0 Ok, 0:1';

                       End Else

                          If Current_Environment.Looped = 0 Then Begin
                             // Non-looped
                             If Current_Environment.CLS = 0 Then Begin
                                // Never CLS
                                AddCommands([#254, LoadString128k+': pause '+PauseStr]);
                                OkMessage := '0 Ok, 0:2';
                                LOADStatement := 1;
                             End Else
                                If Current_Environment.CLS = 1 Then Begin
                                   // CLS every screen
                                   AddCommands([#254, 'cls: '+LoadString128k+': pause '+PauseStr]);
                                   OkMessage := '0 Ok, 0:3';
                                   LOADStatement := 2;
                                End Else Begin
                                   // CLS every n screens
                                   AddCommands([#254, 'cls: for f=1 to '+IntToString(Current_Environment.CLS)+': '+LoadString128k+': pause '+PauseStr+': next f']);
                                   OkMessage := '0 Ok, 0:4';
                                   LOADStatement := 3;
                                End;
                          End Else Begin
                             // Looped.
                             If Current_Environment.Looped = -1 Then Begin
                                // Loop forever
                                If Current_Environment.CLS = 0 Then Begin
                                   // Never CLS
                                   AddCommands([#254, 'for f=0 to 1: '+LoadString128k+': pause '+PauseStr+': let f=0: next f']);
                                   OkMessage := '0 Ok, 0:5';
                                   LOADStatement := 2;
                                End Else
                                   If Current_Environment.CLS = 1 Then Begin
                                      // CLS every screen
                                      AddCommands([#254, 'for f=0 to 1: cls: '+LoadString128k+': pause '+PauseStr+': let f=0: next f']);
                                      OkMessage := '0 Ok, 0:6';
                                      LOADStatement := 3;
                                   End Else Begin
                                      // CLS every n screens
                                      AddCommands([#254, 'for f=0 to 1: cls: for g=1 to '+IntToString(Current_Environment.CLS)+': '+LoadString128k+': pause '+PauseStr+': next g: let f=0: next f']);
                                      OkMessage := '0 Ok, 0:8';
                                      LOADStatement := 4;
                                   End;
                             End Else Begin
                                // Loop for n frames
                                If Current_Environment.CLS = 0 Then Begin
                                   // Never CLS
                                   AddCommands([#254, 'for f=0 to '+IntToString(Current_Environment.Looped)+': '+LoadString128k+': pause '+PauseStr+': next f']);
                                   OkMessage := '0 Ok, 0:4';
                                   LOADStatement := 2;
                                End Else
                                   If Current_Environment.CLS = 1 Then Begin
                                      // CLS every screen
                                      AddCommands([#254, 'for f=0 to '+IntToString(Current_Environment.Looped)+': cls: '+LoadString128k+': pause '+PauseStr+': next f']);
                                      OkMessage := '0 Ok, 0:5';
                                      LOADStatement := 3;
                                   End Else Begin
                                      // CLS every n screens
                                      AddCommands([#254, 'for f=0 to '+IntToString(Current_Environment.Looped)+': cls: for g=1 to '+IntToString(Current_Environment.CLS)+': '+LoadString128k+': pause '+PauseStr+': next g: next f']);
                                      OkMessage := '0 Ok, 0:7';
                                      LOADStatement := 4;
                                   End;
                             End;
                          End;

                    CommandLineLen := High(CommandLine);

                 End;
           End;

        End;

     pgmProgram:
        Begin

           // similar to the command-line version, but stores lines in a program.
           // After each command line, clear the lower screen and then CLS, listing the current prog.
           // Commands are prefixed with #254, program lines to be listed are prefixed with #255.

           Case Current_Environment.HardwareModel of
              h16k, h48k, h128kUsr0, hPlus2Usr0, hPlus2aUsr0, hPlus3Usr0:
                 Begin

                    RUNEntered := True;
                    ProgramStage := ps48kBegin;
                    ProgramX := 0;
                    ProgramPtr := 0;
                    SetLength(CommandLine, 0);

                    If Current_Environment.Looped = 0 Then Begin
                       // Non-looped
                       If Current_Environment.CLS = 0 Then Begin
                          // Never CLS
                          AddCommands([#254, '1', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                          AddCommands([#255, '  10>LOAD ""SCREEN$']);
                          AddCommands([#254, '2', '0', ' PAUSE ']);
                          For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                          AddCommands([#255, '  10 LOAD ""SCREEN$'+#13+'  20>PAUSE '+PauseStr]);
                          AddCommands([#254, 'RUN ']);
                          OkMessage := '0 Ok, 20:1';
                          GOTOLine := 10;
                          LOADLine := 10;
                       End Else
                          If Current_Environment.CLS = 1 Then Begin
                             // CLS every screen
                             AddCommands([#254, '1', '0', ' CLS ']);
                             AddCommands([#255, '  10>CLS ']);
                             AddCommands([#254, '2', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                             AddCommands([#255, '  10 CLS'+#13+'  20>LOAD ""SCREEN$']);
                             AddCommands([#254, '3', '0', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([#255, '  10 CLS'+#13+'  20 LOAD ""SCREEN$'+#13+'  30>PAUSE '+PauseStr]);
                             AddCommands([#254, 'RUN ']);
                             OkMessage := '0 Ok, 30:1';
                             GOTOLine := 10;
                             LOADLine := 20;
                          End Else Begin
                             // CLS every n screens
                             AddCommands([#254, '1', '0', ' CLS ']);
                             AddCommands([#255, '  10>CLS ']);
                             AddCommands([#254, '2', '0', ' FOR ', 'f', '=', '1', ' TO ']);
                             TempStr := IntToString(Current_Environment.CLS);
                             For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                             AddCommands([#255, '  10 CLS '+#13+'20>FOR f=1 TO '+IntToString(Current_Environment.CLS)]);
                             AddCommands([#254, '3', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                             AddCommands([#255, '  10 CLS'+#13+'  20 FOR F=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30>LOAD ""SCREEN$']);
                             AddCommands([#254, '4', '0', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([#255, '  10 CLS'+#13+'  20 FOR F=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30 LOAD ""SCREEN$'+#13+'  40>PAUSE '+PauseStr]);
                             AddCommands([#254, '5', '0', ' NEXT ', 'f']);
                             AddCommands([#255, '  10 CLS'+#13+'  20 FOR f=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30 LOAD ""SCREEN$'+#13+'  40 PAUSE '+PauseStr+#13+'  50>NEXT f']);
                             AddCommands([#254, 'RUN ']);
                             OkMessage := '0 Ok, 50:1';
                             GOTOLine := 50;
                             LOADLine := 30;
                          End;
                    End Else Begin
                       // Looped.
                       If Current_Environment.Looped = -1 Then Begin
                          // Loop forever
                          If Current_Environment.CLS = 0 Then Begin
                             // Never CLS
                             AddCommands([#254, '1', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                             AddCommands([#255, '  10>LOAD ""SCREEN$']);
                             AddCommands([#254, '2', '0', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([#255, '  10 LOAD ""SCREEN$'+#13+'  20>PAUSE '+PauseStr]);
                             AddCommands([#254, '3', '0', ' GO TO ', '1', '0']);
                             AddCommands([#255, '  10 LOAD ""SCREEN$'+#13+'  20 PAUSE '+PauseStr+#13+'  30>GO TO 10']);
                             AddCommands([#254, 'RUN ']);
                             OkMessage := 'D BREAK, Cont repeats 10:1';
                             GOTOLine := 10;
                             LOADLine := 10;
                          End Else
                             If Current_Environment.CLS = 1 Then Begin
                                // CLS every screen
                                AddCommands([#254, '1', '0', ' CLS ']);
                                AddCommands([#255, '  10>CLS']);
                                AddCommands([#254, '2', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                                AddCommands([#255, '  10 CLS'+#13+'  20>LOAD ""SCREEN$']);
                                AddCommands([#254, '3', '0', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([#255, '  10 CLS'+#13+'  20 LOAD ""SCREEN$'+#13+'  30>PAUSE '+PauseStr]);
                                AddCommands([#254, '4', '0', ' GO TO ', '1', '0']);
                                AddCommands([#255, '  10 CLS'+#13+'  20 LOAD ""SCREEN$'+#13+'  30 PAUSE '+PauseStr+#13+'  40>GO TO 10']);
                                AddCommands([#254, 'RUN ']);
                                OkMessage := 'D BREAK, Cont repeats 20:1';
                                GOTOLine := 10;
                                LOADLine := 20;
                             End Else Begin
                                // CLS every n screens
                                AddCommands([#254, '1', '0', ' CLS ']);
                                AddCommands([#255, '  10>CLS']);
                                AddCommands([#254, '2', '0', ' FOR ', 'f', '=', '1', ' TO ']);
                                TempStr := IntToString(Current_Environment.CLS);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([#255, '  10 CLS'+#13+'  20>FOR f=1 TO '+IntToString(Current_Environment.CLS)]);
                                AddCommands([#254, '3', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                                AddCommands([#255, '  10 CLS'+#13+'  20 FOR f=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30>LOAD ""SCREEN$']);
                                AddCommands([#254, '4', '0', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([#255, '  10 CLS'+#13+'  20 FOR f=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30 LOAD ""SCREEN$'+#13+'  40>PAUSE '+PauseStr]);
                                AddCommands([#254, '5', '0', ' NEXT ', 'f']);
                                AddCOmmands([#255, '  10 CLS'+#13+'  20 FOR f=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30 LOAD ""SCREEN$'+#13+'  40 PAUSE '+PauseStr+#13+'  50>NEXT F']);
                                AddCommands([#254, '6', '0', ' GO TO ', '1', '0']);
                                AddCommands([#255, '  10 CLS'+#13+'  20 FOR f=1 TO '+IntToString(Current_Environment.CLS)+#13+'  30 LOAD ""SCREEN$'+#13+'  40 PAUSE '+PauseStr+#13+'  50 NEXT f'+#13+'  60>GO TO 10']);
                                AddCommands([#254, 'RUN ']);
                                OkMessage := 'D BREAK, Cont repeats 30:1';
                                GOTOLine := 50;
                                LOADLine := 30;
                             End;
                       End Else Begin
                          // Loop for n frames
                          If Current_Environment.CLS = 0 Then Begin
                             // Never CLS
                             AddCommands([#254, '1', '0', ' FOR ', 'f', '=', '0', ' TO ']);
                             TempStr := IntToString(Current_Environment.Looped);
                             For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                             AddCommands([#255, '  10>FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                             AddCommands([#254, '2', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                             AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20>LOAD ""SCREEN$']);
                             AddCommands([#254, '3', '0', ' PAUSE ']);
                             For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                             AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 LOAD ""SCREEN$'+#13+'  30>PAUSE '+PauseStr]);
                             AddCommands([#254, '4', '0', ' NEXT ', 'f']);
                             AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 LOAD ""SCREEN$'+#13+'  30 PAUSE '+PauseStr+#13+'  40>NEXT f']);
                             AddCommands([#254, 'RUN ']);
                             OkMessage := '0 Ok, 40:1';
                             GOTOLine := 40;
                             LOADLine := 20;
                          End Else
                             If Current_Environment.CLS = 1 Then Begin
                                // CLS every screen
                                AddCommands([#254, '1', '0', ' FOR ', 'f', '=', '0', ' TO ']);
                                TempStr := IntToString(Current_Environment.Looped);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([#255, '  10>FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                                AddCommands([#254, '2', '0', ' CLS ']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20>CLS']);
                                AddCommands([#254, '3', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30>LOAD ""SCREEN$']);
                                AddCommands([#254, '4', '0', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 LOAD ""SCREEN$'+#13+'  40>PAUSE '+PauseStr]);
                                AddCommands([#254, '5', '0', ' NEXT ', 'f']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 LOAD ""SCREEN$'+#13+'  40 PAUSE '+PauseStr+#13+'  50>NEXT f']);
                                AddCommands([#254, 'RUN ']);
                                OkMessage := '0 Ok, 50:1';
                                GOTOLine := 20;
                                LOADLine := 30;
                             End Else Begin
                                // CLS every n screens
                                AddCommands([#254, '1', '0', ' FOR ', 'f', '=', '0', ' TO ']);
                                TempStr := IntToString(Current_Environment.Looped);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([#255, '  10>FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                                AddCommands([#254, '2', '0', ' CLS ']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20>CLS']);
                                AddCommands([#254, '3', '0', ' FOR ', 'g', '=', '1', ' TO ']);
                                TempStr := IntToString(Current_Environment.CLS);
                                For Idx := 1 To Length(TempStr) Do AddCommands([TempStr[Idx]]);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30>FOR g=1 TO '+IntToString(Current_Environment.CLS)]);
                                AddCommands([#254, '4', '0', ' LOAD ', '"', '"', #0, 'SCREEN$ ']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 FOR g=1 TO '+IntToString(Current_Environment.CLS)+#13+'  40>LOAD ""SCREEN$']);
                                AddCommands([#254, '5', '0', ' PAUSE ']);
                                For Idx := 1 To Length(PauseStr) Do AddCommands([PauseStr[Idx]]);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 FOR g=1 TO '+IntToString(Current_Environment.CLS)+#13+'  40 LOAD ""SCREEN$'+#13+'  50>PAUSE '+PauseStr]);
                                AddCommands([#254, '6', '0', ' NEXT ', 'g']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 FOR g=1 TO '+IntToString(Current_Environment.CLS)+#13+'  40 LOAD ""SCREEN$'+#13+'  50 PAUSE '+PauseStr+#13+'  60>NEXT g']);
                                AddCommands([#254, '7', '0', ' NEXT ', 'f']);
                                AddCommands([#255, '  10 FOR f=0 TO '+IntToString(Current_Environment.Looped)+#13+'  20 CLS'+#13+'  30 FOR g=1 TO '+IntToString(Current_Environment.CLS)+#13+'  40 LOAD ""SCREEN$'+#13+'  50 PAUSE '+PauseStr+#13+'  60 NEXT g'+#13+'  70>NEXT f']);
                                AddCommands([#254, 'RUN ']);
                                OkMessage := 'O Ok, 70:1';
                                GOTOLine := 60;
                                LOADLine := 40;
                             End;
                       End;
                    End;
                    CommandLineLen := High(CommandLine);

                 End;

              h128k, hPlus2, hPlus2a, hPlus3:
                 Begin

                    If Current_Environment.Mode48k = md48BASIC Then
                       ProgramStage := ps128kTo48k
                    Else
                       ProgramStage := ps128kBegin;
                    ProgramX := 0;
                    ProgramPtr := 0;
                    SetLength(CommandLine, 0);

                    If Current_Environment.Mode48k = mdUSR0 Then Begin

                       AddCommands([#254, 'usr0']);

                    End Else

                       If Current_Environment.Mode48k = mdSPECTRUM Then Begin

                          AddCommands([#254, 'spectrum']);
                          If Current_Environment.HardwareModel in [hPlus2a, hPlus3] Then
                             OkMessage := 'OUT 7I, 0:1'
                          Else
                             OkMessage := '0 Ok, 0:1';

                       End Else Begin

                          RUNEntered := True;

                          If Current_Environment.Looped = 0 Then Begin
                             // Non-looped
                             If Current_Environment.CLS = 0 Then Begin
                                // Never CLS
                                AddCommands([#254, '10 '+LoadString128k]);
                                AddCommands([#255, '10 '+LoadStringTokens]);
                                AddCommands([#254, '20 pause '+PauseStr]);
                                AddCommands([#255, '20 PAUSE '+PauseStr]);
                                AddCommands([#254, 'run']);
                                OkMessage := '0 Ok, 20:1';
                                GOTOLine := 10;
                                LOADLine := 10;
                             End Else
                                If Current_Environment.CLS = 1 Then Begin
                                   // CLS every screen
                                   AddCommands([#254, '10 cls']);
                                   AddCommands([#255, '10 CLS']);
                                   AddCommands([#254, '20 '+LoadString128k]);
                                   AddCommands([#255, '20 '+LoadStringTokens]);
                                   AddCommands([#254, '30 pause '+PauseStr]);
                                   AddCommands([#255, '30 PAUSE '+PauseStr]);
                                   AddCommands([#254, 'RUN ']);
                                   OkMessage := '0 Ok, 30:1';
                                   GOTOLine := 10;
                                   LOADLine := 20;
                                End Else Begin
                                   // CLS every n screens
                                   AddCommands([#254, '10 cls']);
                                   AddCommands([#255, '10 CLS']);
                                   AddCommands([#254, '20 for f=1 to '+IntToString(Current_Environment.CLS)]);
                                   AddCommands([#255, '20 FOR f=1 TO '+IntToString(Current_Environment.CLS)]);
                                   AddCommands([#254, '30 '+LoadString128k]);
                                   AddCommands([#255, '30 '+LoadStringTokens]);
                                   AddCommands([#254, '40 pause '+PauseStr]);
                                   AddCommands([#255, '40 PAUSE '+PauseStr]);
                                   AddCommands([#254, '50 next f']);
                                   AddCommands([#255, '50 NEXT f']);
                                   AddCommands([#254, 'run']);
                                   OkMessage := '0 Ok, 50:1';
                                   GOTOLine := 50;
                                   LOADLine := 30;
                                End;
                          End Else Begin
                             // Looped.
                             If Current_Environment.Looped = -1 Then Begin
                                // Loop forever
                                If Current_Environment.CLS = 0 Then Begin
                                   // Never CLS
                                   AddCommands([#254, '10 '+LoadString128k]);
                                   AddCommands([#255, '10 '+LoadStringTokens]);
                                   AddCommands([#254, '20 pause '+PauseStr]);
                                   AddCommands([#255, '20 PAUSE '+PauseStr]);
                                   AddCommands([#254, '30 goto 10']);
                                   AddCommands([#255, '30 GO TO 10']);
                                   AddCommands([#254, 'run']);
                                   OkMessage := 'D BREAK, Cont repeats 10:1';
                                   GOTOLine := 10;
                                   LOADLine := 10;
                                End Else
                                   If Current_Environment.CLS = 1 Then Begin
                                      // CLS every screen
                                      AddCommands([#254, '10 cls']);
                                      AddCommands([#255, '10 CLS']);
                                      AddCommands([#254, '20 '+LoadString128k]);
                                      AddCommands([#255, '20 '+LoadStringTokens]);
                                      AddCommands([#254, '30 pause '+PauseStr]);
                                      AddCommands([#255, '30 PAUSE '+PauseStr]);
                                      AddCommands([#254, '40 goto 10']);
                                      AddCommands([#255, '40 GO TO 10']);
                                      AddCommands([#254, 'run']);
                                      OkMessage := 'D BREAK, Cont repeats 20:1';
                                      GOTOLine := 10;
                                      LOADLine := 20;
                                   End Else Begin
                                      // CLS every n screens
                                      AddCommands([#254, '10 cls']);
                                      AddCommands([#255, '10 CLS']);
                                      AddCommands([#254, '20 for f=1 to '+IntToString(Current_Environment.CLS)]);
                                      AddCommands([#255, '20 FOR f=1 TO '+IntToString(Current_Environment.CLS)]);
                                      AddCommands([#254, '30 '+LoadString128k]);
                                      AddCommands([#255, '30 '+LoadStringTokens]);
                                      AddCommands([#254, '40 pause '+PauseStr]);
                                      AddCommands([#255, '40 PAUSE '+PauseStr]);
                                      AddCommands([#254, '50 next f']);
                                      AddCommands([#255, '50 NEXT f']);
                                      AddCommands([#254, '60 goto 10']);
                                      AddCommands([#255, '60 GO TO 10']);
                                      AddCommands([#254, 'run']);
                                      OkMessage := 'D BREAK, Cont repeats 30:1';
                                      GOTOLine := 50;
                                      LOADLine := 30;
                                   End;
                             End Else Begin
                                // Loop for n frames
                                If Current_Environment.CLS = 0 Then Begin
                                   // Never CLS
                                   AddCommands([#254, '10 for f=0 to '+IntToString(Current_Environment.Looped)]);
                                   AddCommands([#255, '10 FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                                   AddCommands([#254, '20 '+LoadString128k]);
                                   AddCommands([#255, '20 '+LoadStringTokens]);
                                   AddCommands([#254, '30 pause '+PauseStr]);
                                   AddCommands([#255, '30 PAUSE '+PauseStr]);
                                   AddCommands([#254, '40 next f']);
                                   AddCommands([#255, '40 NEXT f']);
                                   AddCommands([#254, 'run']);
                                   OkMessage := '0 Ok, 40:1';
                                   GOTOLine := 40;
                                   LOADLine := 20;
                                End Else
                                   If Current_Environment.CLS = 1 Then Begin
                                      // CLS every screen
                                      AddCommands([#254, '10 for f=0 to '+IntToString(Current_Environment.Looped)]);
                                      AddCommands([#255, '10 FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                                      AddCommands([#254, '20 cls']);
                                      AddCommands([#255, '20 CLS']);
                                      AddCommands([#254, '30 '+LoadString128k]);
                                      AddCommands([#255, '30 '+LoadStringTokens]);
                                      AddCommands([#254, '40 pause '+PauseStr]);
                                      AddCommands([#255, '40 PAUSE '+PauseStr]);
                                      AddCommands([#254, '50 next f']);
                                      AddCommands([#255, '50 NEXT f']);
                                      AddCommands([#254, 'run']);
                                      OkMessage := '0 Ok, 50:1';
                                      GOTOLine := 50;
                                      LOADLine := 30;
                                   End Else Begin
                                      // CLS every n screens
                                      AddCommands([#254, '10 for f=0 to '+IntToString(Current_Environment.Looped)]);
                                      AddCommands([#255, '10 FOR f=0 TO '+IntToString(Current_Environment.Looped)]);
                                      AddCommands([#254, '20 cls']);
                                      AddCommands([#255, '20 CLS']);
                                      AddCommands([#254, '30 for g=1 to '+IntToString(Current_Environment.CLS)]);
                                      AddCommands([#255, '30 FOR g=1 TO '+IntToString(Current_Environment.CLS)]);
                                      AddCommands([#254, '40 '+LoadString128k]);
                                      AddCommands([#255, '40 '+LoadStringTokens]);
                                      AddCommands([#254, '50 pause '+PauseStr]);
                                      AddCommands([#255, '50 PAUSE '+PauseStr]);
                                      AddCommands([#254, '60 next g']);
                                      AddCommands([#255, '60 NEXT g']);
                                      AddCommands([#254, '70 next f']);
                                      AddCommands([#255, '70 NEXT f']);
                                      OkMessage := 'O Ok, 70:1';
                                      GOTOLine := 60;
                                      LOADLine := 40;
                                   End;
                             End;
                          End;
                       End;

                    CommandLineLen := High(CommandLine);

                 End;
           End;

        End;

  End;

End;

Procedure AddCommands(Commands: Array of String);
Var
  Idx, Len: Integer;
Begin

  // Sets up the command line buffer for the "ghost programmer" -
  // these items are used when simulating programming.

  Len := Length(CommandLine);
  SetLength(CommandLine, Length(Commands) + Length(CommandLine));
  For Idx := 0 To High(Commands) do
     CommandLine[Idx + Len] := Commands[Idx];

End;

Procedure MakeHeader(Filename: String);
Var
  ExtPos, Idx: Integer;
  Checksum: Byte;
Begin

  // Sets the Header_Data array to 17 bytes, and fills with a valid
  // Speccy tape header for the given filename. Screen_Data array must be filled
  // at this point, so a correct checksum can be generated.

  SetLength(Header_Data, 18);

  // First make a suitable filename - strip the extension and directory,
  // and truncate to 10 chars if necessary.

  Filename := GetFilename(Filename);
  ExtPos := Pos('.scr', Lower(Filename));
  If ExtPos > 0 Then
     Filename := Copy(Filename, 1, ExtPos -1);
  While Length(Filename) < 10 Do
     Filename := Filename + ' ';
  If Not Current_Environment.LongFilenames Then
     Filename := Copy(Filename, 1, 10);
  Display_Name := Filename;

  If Current_Environment.LongFilenames Then
     SetLength(Header_Data, 18 + Length(Display_Name)-10);

  Header_Data[0] := 3;                         // CODE type byte
  For Idx := 1 To Length(Display_Name) Do
     Header_Data[Idx] := Ord(Filename[Idx]);   // Insert the filename

  Idx := Length(Display_Name);
  Header_Data[Idx+1] := Byte(6912 And 255);    // Low byte of file length
  Header_Data[Idx+2] := Byte(6912 Shr 8);      // High byte of file length
  Header_Data[Idx+3] := Byte(16384 And 255);   // Low byte of address
  Header_Data[Idx+4] := Byte(16384 Shr 8);     // High Byte of address
  Header_Data[Idx+5] := 0;                     // The last two bytes are unused in CODE blocks
  Header_Data[Idx+6] := 0;

  // Calculate the checksum

  Checksum := 3;
  For ExtPos := 0 To 6911 Do
     Checksum := Checksum Xor Screen_Data[ExtPos];

  // And add it to the end.

  Header_Data[Idx+7] := Checksum;

End;

// Graphical procedures for various effects and stuff

Procedure ScrollUp(Ink: Byte);
Var
  X, Y: Integer;
Begin

  // Scrolls the lower screen up by one line

  Inc(ProgramLineCount);
  For Y := 192 - (ProgramLineCount * 8) To 191 - 8 Do
     For X := 0 To 31 Do Begin
        Display[ScreenAddresses[Y] + X] := Display[ScreenAddresses[Y + 8] + X];
        If Y Mod 7 = 0 Then
           Display[AttrAddresses[ScreenAddresses[Y] + X]] := Display[AttrAddresses[ScreenAddresses[Y + 8] + X]];
     End;
  DrawText('                                ', Ink, 0, 23);

End;

Procedure ScrollScreen;
Var
  X, Y: Integer;
Begin

  // Scrolls the whole screen, including attributes

  For Y := 0 To 191 - 8 Do
     For X := 0 To 31 Do Begin
        Display[ScreenAddresses[Y] + X] := Display[ScreenAddresses[Y + 8] + X];
        If Y Mod 7 = 0 Then
           Display[AttrAddresses[ScreenAddresses[Y] + X]] := Display[AttrAddresses[ScreenAddresses[Y + 8] + X]];
     End;
  DrawText('                                ', 56, 0, 23);

End;

Procedure DrawDisplay(BorderColour: Byte; StartTs, EndTs: Integer);
Var
  StartPos, EndPos: TPoint;
  AttrByte, DisplayByte, Ink, Paper, BitValue: Byte;
  X, Y: Integer;
  Colour, ScreenAddr: Integer;
  Ptr: pByte;
  DPtr: pLongWord;
Begin

  CurrentBorder := BorderColour;

  // Draws the border from one TState count to another. This is what draws the
  // stripes while loading data, and renders the pilot tone stripes.

  // If any part of the region bounded by StartTs and EndTs is Display Area, it will
  // be displayed using the data that has been "loaded" to the Display[] array.

  // Convert to screen coordinates. Aligned horizontally to the nearest 8 pixels to the left.
  // If we're off-screen (before the ULA starts drawing) then just bomb out.

  TStatesToScreen(StartTs, StartPos);
  If StartPos.X = -1 Then Begin
     StartPos.X := 0;
     StartPos.Y := 0;
  End;

  TStatesToScreen(EndTs, EndPos);
  If EndPos.X = -1 Then
     Exit;

  // Get a pointer to the DIB at the starting position

  Ptr := DIBHandle;
  Inc(Ptr, StartPos.X + (StartPos.Y * 352));

  // Create a LongWord holding the colour for fast(er) writes to display memory

  Colour := BorderColour + (BorderColour Shl 8) + (BorderColour Shl 16) + (BorderColour Shl 24);

  Y := StartPos.Y;
  X := StartPos.X;
  While Y <= EndPos.Y Do Begin

     While X < 352 Do Begin

        If (Y = EndPos.Y) And (X >= EndPos.X) Then
           Break;

        If (Y > 47) And (Y < 240) And (X > 47) And (X < 304) Then Begin

           // If this is screen area, then fill in the screen from the currently
           // "loaded" data. Decode the Coords into an address in the display array

           ScreenAddr := ScreenAddresses[Y - 48] + ((X - 48) Div 8);
           AttrByte := Display[6144 + ((X - 48) Div 8) + (((Y - 48) Div 8) * 32)];
           DisplayByte := Display[ScreenAddr];

           // Extract colour info - if FLASH specified then swap INK and PAPER.

           If AttrByte And 128 = 0 Then Begin
              Ink := AttrByte And 7;
              Paper := (AttrByte Shr 3) And 7;
              If AttrByte and 64 = 64 Then Begin
                 Inc(Ink, 8);
                 Inc(Paper, 8);
              End;
           End Else Begin
              If FlashState = 0 Then Begin
                 Ink := AttrByte And 7;
                 Paper := (AttrByte Shr 3) And 7;
              End Else Begin
                 Paper := AttrByte And 7;
                 Ink := (AttrByte Shr 3) And 7;
              End;
              If AttrByte and 64 = 64 Then Begin
                 Inc(Ink, 8);
                 Inc(Paper, 8);
              End;
           End;

           // Now decode the display byte into pixel values

           BitValue := 128;
           While BitValue > 0 Do Begin
              If DisplayByte and BitValue > 0 Then
                 Ptr^ := Ink
              Else
                 Ptr^ := Paper;
              Inc(Ptr);
              BitValue := BitValue Shr 1;
           End;

        End Else Begin

           // Otherwise... This is border. Set the full 8 pixels to the border colour

           DPtr := pLongWord(Ptr);
           DPtr^ := Colour;
           Inc(DPtr);
           DPtr^ := Colour;
           Inc(Ptr, 8);

        End;

        Inc(X, 8);

     End;
     X := 0;
     Inc(Y);

  End;

End;

Procedure TStatesToScreen(TStates: Integer; Var ScrPos: TPoint);
Var
  TsPerRow: Integer;
Begin

  // Convert a TState offset into a position on a 352x296 bitmap surface.

  If TStates < 3560 Then Begin

     // If this is too early (the screen is drawn late in the frame), then set it to -1, -1
     // Which can then be picked up and ignored.

     ScrPos.X := -1;
     ScrPos.Y := -1;

  End Else Begin

     // Calculate the row - 224 TStates per row on 48k hardware, 228 TStates per row on 128k/+3s

     Dec(TStates, 3560);

     If Current_Environment.HardwareModel in [h16k, h48k] Then
        TsPerRow := 224
     Else
        TsPerRow := 228;

     ScrPos.Y := TStates Div TsPerRow;

     // And the column

     ScrPos.X := ((TStates - (ScrPos.Y * TsPerRow)) Div 8) * 8;

     If ScrPos.y > 294 Then Begin
        ScrPos.X := 351;
        ScrPos.Y := 295;
     End;

  End;

End;

Procedure DrawText(Text: String; Attr: Byte; X, Y: Integer);
Var
  Idx, Idx2, Address, CharOffset: Integer;
Begin

  // Renders Spectrum text to the memory model. Coordinates are in character
  // squares. The Attr is in spectrum attribute format. Any text written will eventually
  // be overwritten by the screen as it loads.

  For Idx := 1 To Length(Text) Do Begin

     // For each char:
     // Get the offset into the array of character graphics

     CharOffset := (Ord(Text[Idx]) -32) * 8;

     // Convert X and Y to a screen address

     Address := ScreenAddresses[(Y * 8)] + X;

     // And write the bytes to the display memory

     Display[AttrAddresses[Address]] := Attr;
     For Idx2 := 0 To 7 Do Begin
        Display[Address] := CharacterSet[CharOffset];
        Inc(Address, 256);
        Inc(CharOffset);
     End;

     Inc(X);

  End;

End;

// Replacement functions for Windows.pas and others

Procedure CopyMem(Dst, Src: Pointer; Len: LongInt);
Var
  D, S: pByte;
Begin

  // Copies bytes from Src to Dst pointers.

  D := Dst; S := Src;

  While Len > 0 Do Begin
     D^ := S^;
     Inc(D);
     Inc(S);
     Dec(Len);
  End;

End;

Function GetFilename(Name: String): String;
Var
  Ps: Integer;
Begin

  // extracts a filename from a path, ie c:\program files\Screen$\Test.Scr returns Test.Scr

  Ps := Length(Name);
  While Ps > 0 Do Begin
     If Name[Ps] in [':', '\'] Then
        Break;
     Dec(Ps);
  End;
  Result := Copy(Name, Ps +1, Length(Name));

End;

Function Lower(Text: String): String;
Var
  Ps: Integer;
Begin

  // Returns a copy of the supplied string in lowercase.

  SetLength(Result, Length(Text));

  Ps := 1;
  While Ps <= Length(Text) Do Begin
     If Text[Ps] in ['A'..'Z'] Then
        Result[Ps] := Chr(Ord(Text[Ps])+32)
     Else
        Result[Ps] := Text[Ps];
     Inc(Ps);
  End;

End;

Function  IntToString(Value: Integer): String;
Var
  NegFlag: Boolean;
Begin

  // Converts an integer into a string.

  Result := '';
  NegFlag := False;
  If Value < 0 Then Begin
     Value := -Value;
     NegFlag := True;
  End;
  If Value = 0 Then
     Result := '0'
  Else
     While Value > 0 Do Begin
        Result := Chr(48+(Value Mod 10)) + Result;
        Value := Value Div 10;
     End;
  If NegFlag then Result := '-' + Result;

End;


end.
