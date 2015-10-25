; Downloads the newest version of ComboFix
#RequireAdmin
#pragma compile(Icon, icon.ico)
#pragma compile(Out, ComboFix.exe)
#pragma compile(FileDescription, Downloads and runs the newest ComboFix version)
#pragma compile(FileVersion, 1.5)
#pragma compile(ProductVersion, 1.0)
#pragma compile(ProductName, ComboFix)
#pragma compile(UPX, true)
#pragma compile(Compression, 1)

AutoItSetOption("TrayAutoPause", 0)

#include <Date.au3>
#include <Inet.au3>
#Include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <String.au3>

; Variables
$Destination = @TempDir & "\ComboFix.exe"
$URL = StringRegExp(_INetGetSource("http://www.bleepingcomputer.com/download/combofix/dl/12/", True), "<a href='http://download.bleepingcomputer.com/dl/([^:]*?)/windows/security/anti-virus/c/combofix/ComboFix.exe'>click here</a>", 3)
$Name = "ComboFix"

Global $Root = StringLeft(@WindowsDir, 2) & "\"

; If program is being ran while it's not compiled, just download most recent version and use it as the old offline version when it's compiled again
If Not @Compiled Then
   Download("http://download.bleepingcomputer.com/dl/" & $URL[0] & "/windows/security/anti-virus/c/combofix/ComboFix.exe", @ScriptDir & "\old.exe", "Downloading new offline version")
   Exit
EndIf

; Download the latest version
If IsArray($URL) Then
   Download("http://download.bleepingcomputer.com/dl/" & $URL[0] & "/windows/security/anti-virus/c/combofix/ComboFix.exe", $Destination, $Name)
Else
   SetError(256)
EndIf

If @error Then
   ; Error -- install older version
   FileInstall("old.exe", $Destination, 1)
   Sleep(5000)
EndIf

; Run the program
Run($Destination)


; #FUNCTION# ====================================================================================================================
; Name ..........: Download
; Author ........: Michael Rouse
; Syntax ........: Download($sURL, $sDestination [, $sTitle, $bOfflineVersion ])
; Parameters ....: $sURL - The URL to download the file from
;                  $sDestination - The location to put the downloaded file
;                  $aTitle - The name to display on the Progress Bar (Defaults to "File")
;                  $bOfflineVersion - If true then an offline version will be provided
; Description ...: Displays a progress bar while a file is downloading
; ===============================================================================================================================
Func Download($sURL, $sDestination, $sTitle="File", $bOfflineVersion=True)
   If $sTitle = Default Then $sTitle = "File"
   If $bOfflineVersion = Default then $bOfflineVersion = True
   $Error = 0

   ; Create the GUI
   $hGUI = GUICreate("Downloading " & $sTitle, 310, 130, Default, Default, 0x00080000)
   $hMainText = GUICtrlCreateLabel("Connecting to server...", 20, 5, 280, Default, 0x0C)
   GUICtrlSetFont(-1, 12, 600, Default, "Segoe UI")
   $hProgress = GUICtrlCreateProgress(20, 30, 260, 25, 0x01)
   $hSubText = GUICtrlCreateLabel("0%", 20, 60, 280, Default, 0x0C)
   GUICtrlSetFont(-1, 10, 500, Default, "Segoe UI")
   GUISetState()

   ; Get File Size
   $iSize = InetGetSize($sURL, 1) ; 1 = Force reload

   If Not @Error Then
	  ; Able to get file size, start download
	  GUICtrlSetData($hMainText, "Downloading...")

	  FileDelete($sDestination)

	  ; Start the download
	  Local $oInet = InetGet($sURL, $sDestination, 1, 1)

	  Local $iOld_Percent = 0 ; To prevent flickering

	  ; Loop Until download is finished
	  While True
		 ; GUI CASES
		 Switch GUIGEtMsg()
			Case $GUI_EVENT_CLOSE
			   ; Window closed
			   Exit(-251)
		 EndSwitch

		 ; Get new percent
		 $iPercent = Int((InetGetInfo($oInet, 0) / $iSize) * 100)

		 ; Check if the percent has changed
		 If $iPercent > $iOld_Percent Then
			; Show the new percent on the progress bar
			GUICtrlSetData($hProgress, $iPercent)
			GUICtrlSetData($hSubText, String($iPercent) & "%")
			$iOld_Percent = $iPercent
		 EndIf

		 ; Check if download is finished
		 If $iPercent >= 100 And InetGetInfo($oInet, 2) Then
			GUICtrlSetData($hMainText, "Download Finished")
			GUICtrlSetData($hProgress, 100)
			GUICtrlSetData($hSubText, "100%")

			Sleep(2000) ; Short delay

			ExitLoop
		 EndIf
	  WEnd

	  ; Close connection to server
	  InetClose($oInet)
   Else
	  ; Unable to get file size
	  $Error = 250
   EndIf

   Sleep(500)

   ; Make sure downloaded file exists
   If Not FileExists($sDestination) and $Error <> 252 Then
	  $Error = 253
   EndIf

   ; Remove the GUI
   GUIDelete($hGUI)

   ; Set error
   SetError($Error)
EndFunc
