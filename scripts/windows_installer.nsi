!define NAME       "Icestudio"
!ifndef VERSION
  !define VERSION  "dev"
!endif
!ifndef ARCH
  !define ARCH     "win64"
!endif
!define DIST     "..\dist"
!define CACHE    "..\cache"
!define APP      "${DIST}\icestudio\${ARCH}"
!define PYTHON   "python-2.7.13.amd64.msi"
!define PYPATH   "${CACHE}\python\${PYTHON}"
!define ICON     "${APP}\resources\images\icestudio-logo.ico"

# define name of installer
Name "${NAME} ${VERSION}"

# define output file
OutFile ${DIST}\${NAME}-${VERSION}-${ARCH}.exe

# define installation directory
InstallDir $PROGRAMFILES\${NAME}

# Request application privileges
RequestExecutionLevel admin

# SetCompressor lzma


!include MUI2.nsh
!include FileFunc.nsh
!include FileAssociation.nsh

!define MUI_ICON "${ICON}"
!define MUI_BGCOLOR FFFFFF

# Directory page defines
!define MUI_DIRECTORYPAGE_VERIFYONLEAVE

# Run after installing
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start ${NAME} ${VERSION}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"

# Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

# Languages
!insertmacro MUI_LANGUAGE "English"


Function .onInit

  ReadRegStr $R0 HKLM \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" \
  "UninstallString"
  StrCmp $R0 "" done

  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
  "${NAME} is already installed. $\n$\nClick OK to remove the \
  previous version or Cancel to cancel this upgrade." \
  IDOK uninst
  Abort

  # run the uninstaller
  uninst:
    ExecWait '$R0 _?=$INSTDIR'

  done:

FunctionEnd


Section "Install Python"

  Call ValidatePythonVersion
  Pop $R0

  ${If} $R0 != "0"
    MessageBox MB_YESNO \
    "Python 2.7.13 will be installed. Do you want to continue?" \
    IDYES continue
    Quit

    continue:
      # define output path
      SetOutPath "$INSTDIR\python"

      # copy Python msi
      File ${PYPATH}

      # execute Python msi
      ExecWait '"msiexec" /i "$INSTDIR\python\${PYTHON}" /passive /norestart ADDLOCAL=ALL'

  ${EndIf}

SectionEnd

Function ValidatePythonVersion

  nsExec::ExecToStack '"python" "-c" "import sys; ver=sys.version_info[:2]; exit({True:0,False:1}[ver==(2,7)])"'

FunctionEnd


Section "${NAME} ${VERSION}"

  # define output path
  SetOutPath $INSTDIR

  # install app files
  File "${APP}\icestudio.exe"
  File "${APP}\icudtl.dat"
  File "${APP}\nw.pak"
  File /r "${APP}\toolchain"

  File "${APP}\index.html"
  File "${APP}\package.json"
  File /r "${APP}\fonts"
  File /r "${APP}\node_modules"
  File /r "${APP}\resources"
  File /r "${APP}\scripts"
  File /r "${APP}\styles"
  File /r "${APP}\views"

  # define the uninstaller name
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "DisplayName" "${NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "UninstallString" '"$INSTDIR\uninstaller.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstaller.exe"

  # write start menu entries for all users
  SetShellVarContext all

  # define shortcut
  CreateDirectory "$SMPROGRAMS\${NAME}"
  CreateShortCut "$SMPROGRAMS\${NAME}\${NAME}.lnk" "$INSTDIR\icestudio.exe"
  CreateShortCut "$SMPROGRAMS\${NAME}\Uninstall ${NAME}.lnk" "$INSTDIR\uninstaller.exe"

  # register .ice files
  ${registerExtension} "$INSTDIR\icestudio.exe" ".ice" "Icestudio project"
  ${RefreshShellIcons}

SectionEnd


Function LaunchLink

 Exec "$INSTDIR\icestudio.exe"

FunctionEnd


Section "Uninstall"

  # delete the uninstaller
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}"
  Delete "$INSTDIR\uninstaller.exe"

  # write start menu entries for all users
  SetShellVarContext all

  # delete the installed files
  Delete "$SMPROGRAMS\${NAME}"
  RMDir /r $INSTDIR

  # unregister .ice files
  ${unregisterExtension} ".ice" "Icestudio project"
  ${RefreshShellIcons}

SectionEnd
