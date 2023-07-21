Attribute VB_Name = "WebDriverManager4TinySelenium"
Option Explicit

Enum BrowserName
    Chrome
    Edge
End Enum

#Const DEV = 0

'// �t�@�C���_�E�����[�h�p��Win32API
#If VBA7 Then
Private Declare PtrSafe Function URLDownloadToFile Lib "urlmon" Alias "URLDownloadToFileA" _
    (ByVal pCaller As LongPtr, ByVal szURL As String, ByVal szFileName As String, ByVal dwReserved As Long, ByVal lpfnCB As LongPtr) As Long
Private Declare PtrSafe Function DeleteUrlCacheEntry Lib "wininet" Alias "DeleteUrlCacheEntryA" (ByVal lpszUrlName As String) As Long
#Else
Private Declare Function URLDownloadToFile Lib "urlmon" Alias "URLDownloadToFileA" _
    (ByVal pCaller As Long, ByVal szURL As String, ByVal szFileName As String, ByVal dwReserved As Long, ByVal lpfnCB As Long) As Long
Private Declare Function DeleteUrlCacheEntry Lib "wininet" Alias "DeleteUrlCacheEntryA" (ByVal lpszUrlName As String) As Long
#End If




#If DEV Then
    Dim fso As New Scripting.FileSystemObject
    Dim wsh As New WshShell
    Dim shell As New Shell32.shell
#Else
    Private Property Get fso() As Object
        Static Obj As Object
        If Obj Is Nothing Then Set Obj = CreateObject("Scripting.FileSystemObject")
        Set fso = Obj
    End Property
    
    Private Property Get wsh() As Object
        Static Obj As Object
        If Obj Is Nothing Then Set Obj = CreateObject("WScript.Shell")
        Set wsh = Obj
    End Property
    
    Private Property Get shell() As Object
        Static Obj As Object
        If Obj Is Nothing Then Set Obj = CreateObject("Shell.Application")
        Set shell = Obj
    End Property
#End If


Public Property Get ZipPath(Browser As BrowserName) As String
    Dim DownloadFolderPath As String
    DownloadFolderPath = shell.Namespace("shell:Downloads").Self.path
    
    Select Case Browser
    Case BrowserName.Chrome
        Select Case Is64BitOS
            Case True: ZipPath = DownloadFolderPath & "\chromedriver-win64.zip"
            Case Else: ZipPath = DownloadFolderPath & "\chromedriver-win32.zip"
        End Select
        
    Case BrowserName.Edge
        Select Case Is64BitOS
            Case True: ZipPath = DownloadFolderPath & "\edgedriver_win64.zip"
            Case Else: ZipPath = DownloadFolderPath & "\edgedriver_win32.zip"
        End Select
    End Select
End Property


Public Property Get WebDriverPath(Browser As BrowserName) As String
    Dim MyDocuments As String
    MyDocuments = wsh.SpecialFolders("MyDocuments")
    Select Case Browser
        Case BrowserName.Chrome: WebDriverPath = MyDocuments & "\WebDriver\chromedriver.exe"
        Case BrowserName.Edge:   WebDriverPath = MyDocuments & "\WebDriver\edgedriver.exe"
    End Select
End Property

Public Property Get BrowserVersion(Browser As BrowserName)
    Dim EdgePath1 As String
    Dim EdgePath2 As String
    Dim EdgePath3 As String
    Dim ChromePath1 As String
    Dim ChromePath2 As String
    Dim ChromePath3 As String
    EdgePath1 = Environ("Programfiles(x86)") & "\Microsoft\Edge\Application\msedge.exe"
    EdgePath2 = Environ("ProgramW6432") & "\Microsoft\Edge\Application\msedge.exe"
    EdgePath3 = Environ("Programfiles") & "\Microsoft\Edge\Application\msedge.exe"
    ChromePath1 = Environ("Programfiles(x86)") & "\Google\Chrome\Application\chrome.exe"
    ChromePath2 = Environ("ProgramW6432") & "\Google\Chrome\Application\chrome.exe"
    ChromePath3 = Environ("Programfiles") & "\Google\Chrome\Application\chrome.exe"
    
    Dim BrowserFilePath As String
    Dim TargetFile
    Select Case Browser
    Case Edge
        Select Case True
            Case fso.FileExists(EdgePath1): BrowserFilePath = EdgePath1
            Case fso.FileExists(EdgePath2): BrowserFilePath = EdgePath2
            Case fso.FileExists(EdgePath3): BrowserFilePath = EdgePath3
        End Select

        
    Case Chrome
        Select Case True
            Case fso.FileExists(ChromePath1): BrowserFilePath = ChromePath1
            Case fso.FileExists(ChromePath2): BrowserFilePath = ChromePath2
            Case fso.FileExists(ChromePath3): BrowserFilePath = ChromePath3
        End Select
    End Select
    
    BrowserVersion = fso.GetFileVersion(BrowserFilePath)
End Property

'// �o�͗�@"94"
Public Property Get ToMajor(Version As String)
    Dim Vers
    Vers = Split(Version, ".")
    ToMajor = Vers(0)
End Property
'// �o�͗�@"94.0"
Public Property Get ToMinor(Version As String)
    Dim Vers
    Vers = Split(Version, ".")
    ToMinor = Join(Array(Vers(0), Vers(1)), ".")
End Property
'// �o�͗�@"94.0.992"
Public Property Get ToBuild(Version As String)
    Dim Vers
    Vers = Split(Version, ".")
    ToBuild = Join(Array(Vers(0), Vers(1), Vers(2)), ".")
End Property


'// OS��64Bit���ǂ����𔻒肷��
Public Property Get Is64BitOS() As Boolean
    Dim Arch As String
    '�߂�l "AMD64","IA64","x86"�̂����ꂩ
    Arch = wsh.Environment("Process").Item("PROCESSOR_ARCHITECTURE")
    '64bitOS��32bitOffice�����s���Ă���ꍇ�APROCESSOR_ARCHITEW6432�ɖ{����OS��bit�����ޔ�����Ă���̂Ŋm�F
    If InStr(Arch, "64") = 0 Then Arch = wsh.Environment("Process").Item("PROCESSOR_ARCHITEW6432")
    Is64BitOS = InStr(Arch, "64")
End Property


Public Function DownloadWebDriver(Browser As BrowserName, Version As String, Optional PathSaveTo As String) As String
    Dim url As String
    If PathSaveTo = "" Then PathSaveTo = ZipPath(Browser)
    
    Select Case Browser
    Case BrowserName.Chrome
        Select Case True
            Case ToMajor(Version) < 115: url = Replace("https://chromedriver.storage.googleapis.com/{version}/chromedriver_win32.zip", "{version}", Version)
            Case Is64BitOS:              url = Replace("https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/{version}/win64/chromedriver-win64.zip", "{version}", Version)
            Case Else:                   url = Replace("https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/{version}/win32/chromedriver-win32.zip", "{version}", Version)
        End Select
        
    Case BrowserName.Edge
        Select Case Is64BitOS
            Case True: url = Replace("https://msedgedriver.azureedge.net/{version}/edgedriver_win64.zip", "{version}", Version)
            Case Else: url = Replace("https://msedgedriver.azureedge.net/{version}/edgedriver_win32.zip", "{version}", Version)
        End Select
    End Select
    
    Dim ret As Long
    DeleteUrlCacheEntry url
    ret = URLDownloadToFile(0, url, PathSaveTo, 0, 0)
    If ret <> 0 Then Err.Raise 4001, , "�_�E�����[�h���s : " & url
    DownloadWebDriver = PathSaveTo
End Function

Public Function Extract(PathFrom As String, Optional PathTo As String) As String
    
    ' hoge.zip �� hoge
    If PathTo = "" Then PathTo = Left(PathFrom, Len(PathFrom) - 4)
    
    Debug.Print "zip��W�J���܂�"
    fso.CreateFolder PathTo
    Debug.Print "    �ꎞ�t�H���_ : " & PathTo
    
    'PowerShell���g���ēW�J����ƃ}���E�F�A���肳�ꂽ�̂ŁC
    'MS�񐄏�����Shell.Application���g����zip���𓀂���
    
    On Error GoTo Catch
    'zip�t�@�C���ɓ����Ă���t�@�C�����w�肵���t�H���_�[�ɃR�s�[����
    '���������x()�ŕ]�����Ă���Namespace�ɓn���Ȃ��ƃG���[���o��
    shell.Namespace((PathTo)).CopyHere shell.Namespace((PathFrom)).Items
    Extract = PathTo
    Exit Function
Catch:
    fso.DeleteFolder PathTo, True
    Err.Raise 4002, , "Zip�̓W�J�Ɏ��s���܂����B�����F" & Err.Description
    Exit Function
End Function

Public Function FindExe(FolderPath) As String
    Dim f
    For Each f In fso.GetFolder(FolderPath).Files
        If f.Name Like "*.exe" Then FindExe = f.path
        If FindExe <> "" Then Exit Function
    Next

    For Each f In fso.GetFolder(FolderPath).SubFolders
        FindExe = FindExe(f)
        If FindExe <> "" Then Exit Function
    Next
End Function


Public Function RequestWebDriverVersion(ChromeVer As String) As String
    Dim http 'As XMLHTTP60
    Dim url As String
    
    Set http = CreateObject("MSXML2.ServerXMLHTTP")
    url = "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_" & ChromeVer
    http.Open "GET", url, False
    http.send
    
    If http.statusText = "OK" Then
        RequestWebDriverVersion = http.responseText
        Exit Function
    End If
    
    Set http = CreateObject("MSXML2.ServerXMLHTTP")
    url = "https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build.json"
    http.Open "GET", url, False
    http.send
    
    If http.statusText <> "OK" Then
        Err.Raise 4003, , "�K���h���C�o�[�̏����擾�ł��܂���ł���"
        Exit Function
    End If
    
    RequestWebDriverVersion = ParseJson(http.responseText)("builds")(ChromeVer)("version")
End Function



Public Sub InstallWebDriver(Browser As BrowserName, DriverPathTo As String)
    
    If DriverPathTo = "" Then DriverPathTo = WebDriverPath(Browser)
    
    Debug.Print "WebDriver���C���X�g�[�����܂�......"
    
    Dim BrowserVer   As String
    Dim DriverVer As String
    BrowserVer = BrowserVersion(Browser)
    Select Case Browser
        Case BrowserName.Chrome: DriverVer = RequestWebDriverVersion(ToBuild(BrowserVer))
        Case BrowserName.Edge:   DriverVer = BrowserVer
    End Select
    
    Debug.Print "   �u���E�U          : Ver. " & BrowserVer
    Debug.Print "   �K������WebDriver : Ver. " & DriverVer
    
    Dim ZipFile As String
    ZipFile = DownloadWebDriver(Browser, DriverVer)
    
    Do Until fso.FileExists(ZipFile)
        DoEvents
    Loop
    Debug.Print "   �_�E�����[�h����:" & ZipFile
    
    
    If Not fso.FolderExists(fso.GetParentFolderName(DriverPathTo)) Then
        Debug.Print "   WebDriver�̕ۑ���t�H���_���쐬���܂�"
        CreateFolderEx fso.GetParentFolderName(DriverPathTo)
    End If
    
    Dim ExtractedFolder As String
    ExtractedFolder = Extract(ZipFile)
    
    Dim ExePath As String
    ExePath = FindExe(ExtractedFolder)
    
    If fso.FileExists(DriverPathTo) Then fso.DeleteFile DriverPathTo, True
    fso.CopyFile ExePath, DriverPathTo, True
    
    fso.DeleteFolder ExtractedFolder
    Debug.Print "    �W�J : " & DriverPathTo
    Debug.Print "WebDriver��z�u���܂���"
    Debug.Print "�C���X�g�[������"
End Sub

Public Sub CreateFolderEx(path_folder As String)
    '// �e�t�H���_���k��Ȃ��Ȃ�Ƃ���܂ōċA�ŒH��
    If fso.GetParentFolderName(path_folder) <> "" Then
        CreateFolderEx fso.GetParentFolderName(path_folder)
    End If
    '// �r���̑��݂��Ȃ��t�H���_���쐬���Ȃ���~��Ă���
    If Not fso.FolderExists(path_folder) Then
        fso.CreateFolder path_folder
    End If
End Sub



Public Sub SafeOpen(Driver As WebDriver, Browser As BrowserName, Optional CustomDriverPath As String)
    
    Dim driverPath As String
    driverPath = IIf(CustomDriverPath <> "", CustomDriverPath, WebDriverPath(Browser))
    
    '// �A�b�v�f�[�g����
    If Not IsLatestDriver(Browser, driverPath) Then
        Dim TmpDriver As String
        If fso.FileExists(driverPath) Then TmpDriver = BuckupTempDriver(driverPath)
        
        Call InstallWebDriver(Browser, driverPath)
    End If
    
    On Error GoTo Catch
    Select Case Browser
        Case BrowserName.Chrome: Driver.Chrome driverPath
        Case BrowserName.Edge:   Driver.Edge driverPath
    End Select
    Driver.OpenBrowser
    
    If TmpDriver <> "" Then Call DeleteTempDriver(TmpDriver)
    Exit Sub
    
Catch:
    If TmpDriver <> "" Then Call RollbackDriver(TmpDriver, driverPath)
    Err.Raise Err.Number, , Err.Description
    
End Sub


'// �h���C�o�[�̃o�[�W�����𒲂ׂ�
Function DriverVersion(driverPath As String) As String
    
    If Not fso.FileExists(driverPath) Then DriverVersion = "": Exit Function
    
    Dim TempFile
    Dim VersionInfo
    TempFile = Environ$("TMP") & "\DriverVersion_" & Format$(Now, "YYYYMMDDHHMMSS") & ".txt"
    CreateObject("WScript.Shell").Run "cmd /c " & driverPath & " -version >" & TempFile, 0, True
    
    With fso.OpenTextFile(TempFile)
        VersionInfo = .ReadLine
        .Close
    End With
    
    fso.DeleteFile TempFile, True
    
    '�o�[�W������񂪎擾�ł��Ȃ��Â��o�[�W����������
    If VersionInfo = "" Then DriverVersion = "": Exit Function
    
    Dim reg
    Set reg = CreateObject("VBScript.RegExp")
    reg.Pattern = "\d+\.\d+\.\d+(\.\d+|)"
    
    On Error Resume Next
    DriverVersion = reg.Execute(VersionInfo)(0).value
End Function

'// �ŐV�̃h���C�o�[���C���X�g�[������Ă��邩���ׂ�
Function IsLatestDriver(Browser As BrowserName, driverPath As String) As Boolean
    Select Case Browser
    Case BrowserName.Edge
        IsLatestDriver = BrowserVersion(Edge) = DriverVersion(driverPath)
    
    '// Chrome�͖����̃o�[�W�������u���E�U�ƃh���C�o�[�ňقȂ邱�Ƃ�����
    Case BrowserName.Chrome
        IsLatestDriver = RequestWebDriverVersion(ToBuild(BrowserVersion(Chrome))) = DriverVersion(driverPath)
    
    End Select
End Function

'// WebDriver���ꎞ�t�H���_�ɑޔ�������
Function BuckupTempDriver(driverPath As String) As String
    Dim TempFolder As String
    TempFolder = fso.BuildPath(fso.GetParentFolderName(driverPath), fso.GetTempName)
    fso.CreateFolder TempFolder
    
    Dim TempDriver As String
    TempDriver = fso.BuildPath(TempFolder, fso.GetFileName(driverPath))
    fso.MoveFile driverPath, TempDriver
    
    BuckupTempDriver = TempDriver
End Function

'// �ꎞ�I�Ɏ���Ă������Â�WebDriver���ꎞ�t�H���_����WebDriver�u����ɖ߂�
Sub RollbackDriver(TempDriverPath As String, driverPath As String)
    fso.CopyFile TempDriverPath, driverPath, True
    fso.DeleteFolder fso.GetParentFolderName(TempDriverPath)
End Sub

'// �ꎞ�I�Ɏ���Ă������Â�WebDriver���폜����
Sub DeleteTempDriver(TempDriverPath As String)
    fso.DeleteFolder fso.GetParentFolderName(TempDriverPath)
End Sub

'�ȈՓI��Json�p�[�T�[
Function ParseJson(Json As String) As Object
    Dim i As Long
    Dim s0 As String
    Dim s1 As String
    i = 1
    Do While i <= Len(Json)
        SkipNull Json, i
        Select Case Mid(Json, i, 1)
        Case "{"
            i = i + 1
            Set ParseJson = ParseObject(Json, i)
            Exit Function
        End Select
    Loop
    
End Function

Private Sub SkipNull(Json, ByRef i)
    Dim s As String
    s = Mid(Json, i, 1)
    Do While s = " " Or s = vbCr Or s = vbLf Or s = vbTab
        i = i + 1
        s = Mid(Json, i, 1)
    Loop
    
End Sub

Private Function ParseObject(Json As String, ByRef i)
    Dim Obj As Object
    Set Obj = CreateObject("Scripting.Dictionary")
    Dim key
    
    Do
        SkipNull Json, i
        If Mid(Json, i, 1) <> """" Then Err.Raise 4000, , "Json�̃p�[�X�Ɏ��s"
        i = i + 1
        key = ParseString(Json, i)
        
        SkipNull Json, i
        If Mid(Json, i, 1) <> ":" Then Err.Raise 4000, , "Json�̃p�[�X�Ɏ��s"
        i = i + 1
        
        SkipNull Json, i
        Select Case Mid(Json, i, 1)
        Case """"
            i = i + 1
            Let Obj(key) = ParseString(Json, i)
        Case "{"
            i = i + 1
            Set Obj(key) = ParseObject(Json, i)
        Case "["
            i = i + 1
            Set Obj(key) = ParseArray(Json, i)
        End Select
        
        SkipNull Json, i
        
        Select Case Mid(Json, i, 1)
        Case ","
            i = i + 1
        Case "}"
            i = i + 1
            Set ParseObject = Obj
            Exit Do
        End Select
    Loop
End Function

Private Function ParseArray(Json As String, ByRef i)
    Dim Arr As Collection
    Set Arr = New Collection
    
     Do
        SkipNull Json, i
        Select Case Mid(Json, i, 1)
        Case """"
            i = i + 1
            Arr.Add ParseString(Json, i)
        Case "{"
            i = i + 1
            Arr.Add ParseObject(Json, i)
        Case "["
            i = i + 1
            Arr.Add ParseArray(Json, i)
        End Select
        
        SkipNull Json, i
        
        Select Case Mid(Json, i, 1)
        Case ","
            i = i + 1
        Case "]"
            i = i + 1
            Set ParseArray = Arr
            Exit Do
        End Select
    Loop
End Function

Private Function ParseString(Json, i) As String
    Dim s As String
    ParseString = ""
    Do
        s = Mid(Json, i, 1)
        If s = """" Then
            i = i + 1
            Exit Do
        End If
        ParseString = ParseString & s
        i = i + 1
    Loop
End Function
