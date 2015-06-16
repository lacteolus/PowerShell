param($sourceDir, $destDir)

function _Exit {
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit-PSSession
}

# Путь к CUESHEET
$cueName = Get-Childitem "$sourceDir*" -include *.cue

# Проверяем основные поля
try {$Date = (Select-String -encoding default -path $sourceDir\*.cue -pattern "DATE" –casesensitive -list | Select-Object -ExpandProperty line).SubString(9)}
catch {$Date = ""}
try {$Artist = (Select-String -encoding default -path $sourceDir\*.cue -pattern "PERFORMER" –casesensitive -list | Select-Object -ExpandProperty line).SubString(10) -replace'"'}
catch {$Artist = ""}
try {$Album = (Select-String -encoding default -path $sourceDir\*.cue -pattern "TITLE" –casesensitive -list | Select-Object -ExpandProperty line).SubString(6) -replace'"'}
catch {$Album = ""}

If (($Date -eq "") -or ($Artist -eq "") -or ($Album -eq "")){
# Выводим сообщение об отсутствии основных полей
	Write-Host "В файле CUESHEET не найдено одно или несколько обязательных полей:" -ForegroundColor "Red"
	Write-Host "ARTIST: "`t$Artist
	Write-Host "ALBUM: "`t$Album
	Write-Host "DATE: "`t$Date
	Write-Host "Нажмите любую клавишу чтобы выйти из скрипта и отредактировать CUESHEET ..." -ForegroundColor "Red" -nonewline
# Нажатие клавиши, открытие CUESHEET и выход из скрипта		
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
	& notepad $cueName
	Exit
}

# Проверяем дополнительные поля
try {$Genre = (Select-String -encoding default -path $sourceDir\*.cue -pattern "GENRE" –casesensitive -list | Select-Object -ExpandProperty line).SubString(10) -replace'"'}
catch {$Genre = ""}
try {$Edition = (Select-String -encoding default -path $sourceDir\*.cue -pattern "EDITION" –casesensitive -list | Select-Object -ExpandProperty line).SubString(13) -replace'"'}
catch {$Edition = ""}

If (($Genre -eq "") -or ($Edition -eq "")){
# Выводим сообщение об отсутствии дополнительных полей
	Write-Host "В файле CUESHEET не найдено одно или несколько дополнительных полей:" -ForegroundColor "Red"
	Write-Host "GENRE: "`t$Genre
	Write-Host "EDITION: "`t$Edition
	Write-Host "Нажмите любую клавишу чтобы выйти из скрипта и отредактировать CUESHEET" -ForegroundColor "Red" 
	Write-Host "или дождитесь продолжения выполнения " -ForegroundColor "Red" -nonewline
	$i = 0
# Ждем 5 секунд или нажатия любой клавиши	
	Do {
		Start-Sleep –s 1
		Write-Host "." -ForegroundColor "Red" -nonewline
		$i++
	} Until (($i -eq 5) -or $Host.UI.RawUI.KeyAvailable)
# Нажатие клавиши, открытие CUESHEET и выход из скрипта	
	If ($Host.UI.RawUI.KeyAvailable) {
		& notepad $cueName
		Exit
	}
Write-Host
Write-Host
}

Write-Host **************************************************************************
Write-Host Информация об альбоме
Write-Host "ARTIST:   " -nonewline
Write-Host `t$Artist -ForegroundColor "White"
Write-Host "ALBUM:    " -nonewline
Write-Host `t$Album -ForegroundColor "White"
Write-Host "DATE:     " -nonewline
Write-Host `t$Date -ForegroundColor "White"
Write-Host "GENRE:    " -nonewline
Write-Host `t$Genre -ForegroundColor "White"
Write-Host "EDITION:  " -nonewline
Write-Host `t$Edition -ForegroundColor "White"
Write-Host **************************************************************************

# Формируем новое имя файла
If ($Edition -ne ""){
	$destFileNoExt = "$Artist - $Date - $Album ($Edition)" -replace "[`?`*]"
}
else {
	$destFileNoExt = "$Artist - $Date - $Album" -replace "[`?`*]"
}
	
# Сообщения об исходном каталоге и целевом файле
Write-Host
Write-Host **************************************************************************
Write-Host Создание файла ISO.WV
Write-Host "Исходный каталог: " -nonewline
Write-Host $sourceDir -ForegroundColor "White"
Write-Host "Целевой файл: " -nonewline
Write-Host $destDir$destFileNoExt.iso.wv -ForegroundColor "White"
Write-Host **************************************************************************
Write-Host

# Переименовываем файлы и исправляем имя файла в CUE
Write-Host **************************************************************************
Write-Host "Переименовываем файлы и правим CUE..." -ForegroundColor "DarkCyan"
Write-Host
# Переименовываем файлы
$colFiles = Get-ChildItem "$sourceDir" | Where {-not $_.psiscontainer}
ForEach ($objFile In $colFiles){
	$ext = $objFile.extension
	Rename-Item -path "$sourceDir$objFile" -newname $destFileNoExt$ext
}
# Исправляем имя файла в CUE
(Get-Content "$sourceDir$destFileNoExt.cue") -creplace "FILE .+$", "FILE ""$destFileNoExt.wv"" WAVE" | Set-Content "$sourceDir$destFileNoExt.cue"
# Выводим список файлов и каталогов в исходной директории
Get-ChildItem "$sourceDir" -name
Write-Host
Write-Host "Выполнено" -ForegroundColor "Green"
Write-Host **************************************************************************
Write-Host

# Файл CUE
$cueName = Get-Childitem "$sourceDir*" -include *.cue -name
# Файл с настройками ImgBurm
$imgRurnProj = "$sourceDir" + "ISOProject.IBB"

# Функция кодировки в WV и проверки контрольной суммы
function WaveToWV {
	Write-Host **************************************************************************
	Write-Host "Выполняется перекодирование файла из WAVE в WAVEPACK:" -ForegroundColor "DarkCyan"
	Write-Host "$destFileNoExt.wav" -ForegroundColor "White"
	.\wavpack.exe -h -ml -y -d "$sourceDir$destFileNoExt.wav" "$sourceDir$destFileNoExt.wv"
	Write-Host
	Write-Host "Успешно создан файл:" -ForegroundColor "Green"
	Write-Host "$destFileNoExt.wv" -ForegroundColor "White"
	Write-Host **************************************************************************
	Write-Host
	Write-Host **************************************************************************
	Write-Host "Выполняется проверка файла:" -ForegroundColor "DarkCyan"
	Write-Host "$destFileNoExt.wv" -ForegroundColor "White"
	.\wvunpack.exe -vml "$sourceDir$destFileNoExt.wv"
	Write-Host
	Write-Host "Успешно завершена проверка файла:" -ForegroundColor "Green"
	Write-Host "$destFileNoExt.wv" -ForegroundColor "White"
	Write-Host **************************************************************************
	Write-Host
	Remove-Item $sourceDir$sourceFile
}

# Функция перекодировки в WAVE
function Convertion {
# Перекодировка из APE в WAVE
	If (Test-Path "$sourceDir*.ape"){
		$sourceFile = Get-Childitem "$sourceDir*" -include *.ape -name
		Write-Host **************************************************************************
		Write-Host "Выполняется перекодирование файла из APE в WAVE:" -ForegroundColor "DarkCyan"
		Write-Host $sourceFile -ForegroundColor "White"
		Write-Host
		.\mac.exe "$sourceDir$sourceFile" "$sourceDir$destFileNoExt.wav" -d
		Write-Host
		Write-Host "Успешно создан файл:" -ForegroundColor "Green"
		Write-Host "$destFileNoExt.wav" -ForegroundColor "White"
		Write-Host **************************************************************************
		Write-Host
		WaveToWV
		Return
	}
# Перекодировка из FLAC в WAVE
	If (Test-Path "$sourceDir*.flac"){
		$sourceFile = Get-Childitem "$sourceDir*" -include *.flac -name
		Write-Host **************************************************************************
		Write-Host "Выполняется перекодирование файла из FLAC в WAVE:" -ForegroundColor "DarkCyan"
		Write-Host $sourceFile -ForegroundColor "White"
		.\flac.exe -dVf --no-decode-through-errors --output-name="$sourceDir$destFileNoExt.wav" "$sourceDir$sourceFile"
		Write-Host
		Write-Host "Успешно создан файл:" -ForegroundColor "Green"
		Write-Host "$destFileNoExt.wav" -ForegroundColor "White"
		Write-Host **************************************************************************
		Write-Host
		WaveToWV
		Return
	}	
# Если исходный файл уже в WAVE
	If (Test-Path "$sourceDir*.wav"){
		$sourceFile = Get-Childitem "$sourceDir*" -include *.wav -name
		WaveToWV
		Return
	}
}

# Функция создания ISO
function MakeISO {
# Заполняем файл настроек ImgBurn
Add-Content -path $sourceDir"ISOProject.IBB" -value "IBB"
Add-Content -path $sourceDir"ISOProject.IBB" -value "[START_BACKUP_OPTIONS]"
Add-Content -path $sourceDir"ISOProject.IBB" -value "VolumeLabel_ISO9660=$destFileNoExt"
Add-Content -path $sourceDir"ISOProject.IBB" -value "VolumeLabel_Joliet=$destFileNoExt"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Identifier_Publisher=DK"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Identifier_Preparer=DK"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_InterchangeLevel=2"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_CharacterSet=0"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_AllowMoreThan8DirectoryLevels=0"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_AllowMoreThan255CharactersInPath=0"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_AllowFilesWithoutExtensions=1"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_ISO9660_DontAddVersionNumberToFiles=0"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_Joliet_InterchangeLevel=1"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_Joliet_AllowFilesWithoutExtensions=1"
Add-Content -path $sourceDir"ISOProject.IBB" -value "Restrictions_Joliet_AddVersionNumberToFiles=0"
Add-Content -path $sourceDir"ISOProject.IBB" -value "[END_BACKUP_OPTIONS]"
Add-Content -path $sourceDir"ISOProject.IBB" -value "[START_BACKUP_LIST]"
Get-Childitem "$sourceDir" -exclude *.IBB | Add-Content -path $sourceDir"ISOProject.IBB" 
Add-Content -path $sourceDir"ISOProject.IBB" -value "[END_BACKUP_LIST]"
# Запускаем создание ISO
& "c:\Program Files (x86)\ImgBurn\ImgBurn.exe" /MODE ISOBUILD /BUILDMODE IMAGEFILE /DEST "$sourceDir$destFileNoExt.iso" /FILESYSTEM "ISO9660 + Joliet" /START /PRESERVEFULLPATHNAMES NO /SRC "$imgRurnProj" /CLOSESUCCESS /NOIMAGEDETAILS
Write-Host **************************************************************************
# Выводим "строку прогресса"
Write-Host "Создается образ ISO " -ForegroundColor "DarkCyan" -nonewline
While ( (Get-Process | Where{$_.ProcessName -eq "ImgBurn"}) -ne $null){
	Start-Sleep –s 1
	Write-Host "."  -ForegroundColor "DarkCyan" -nonewline
}
Write-Host
# Удаляем файл настроек ImgBurn
Remove-Item $sourceDir"ISOProject.IBB"
Write-Host "Успешно создан файл:" -ForegroundColor "Green"
Write-Host "$destFileNoExt.iso" -ForegroundColor "White"
Write-Host **************************************************************************
Write-Host
Write-Host **************************************************************************
Write-Host "Переименовываем файл в:" -ForegroundColor "DarkCyan"
Write-Host "$destFileNoExt.iso.wv" -ForegroundColor "White"
Write-Host "Выполнено" -ForegroundColor "Green"
Write-Host **************************************************************************
Write-Host
# Переименовываем ISO в ISO.WV
Rename-Item -path "$sourceDir$destFileNoExt.iso" -newname "$destFileNoExt.iso.wv"
}

# Функция заполнения тэгов ($a - имя файла CUE, $b - имя файла *.wv или *.iso.wv
function TagFile ($a,$b){
	Write-Host **************************************************************************
	Write-Host "Выполняется запись тэгов в файл:" -ForegroundColor "DarkCyan"
	Write-Host $b -ForegroundColor "White"
	Write-Host
	& .\tag.exe -t "EDITION=$Edition" -t "Artist=$Artist" -t "Album=$Album" -t "Date=$Date" -t "Album Artist=$Artist" -t "Genre=$Genre" -f "cuesheet=$sourceDir$a" "$sourceDir$b" --hidetags --hidenames
	Write-Host
	Write-Host "Успешно завершена запись тэгов в файл:" -ForegroundColor "Green"
	Write-Host $b -ForegroundColor "White"
	Write-Host **************************************************************************
	Write-Host
}

# Основные операции. Конвертирование
Convertion
# Основные операции. Запись тэгов в файл *.wv
TagFile $cueName "$destFileNoExt.wv"
# Основные операции. Создание ISO
MakeISO
# Основные операции. Запись тэгов в файл *.iso.wv
TagFile $cueName "$destFileNoExt.iso.wv"

Write-Host **************************************************************************
Write-Host "Перемещаем файл в:" -ForegroundColor "DarkCyan"
Write-Host "$destDir$destFileNoExt.iso.wv" -ForegroundColor "White"
# Перемещаем файл ISO.WV в целевой каталог с перезаписью
Move-Item -path "$sourceDir$destFileNoExt.iso.wv" -destination "$destDir$destFileNoExt.iso.wv" -force
Write-Host "Выполнено" -ForegroundColor "Green"
Write-Host **************************************************************************
Write-Host 
Write-Host "ГОТОВО!" -ForegroundColor "Green"
Write-Host "Нажмите любую клавишу для выхода..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
# Выход из скрипта
Exit
