# Делаем мужчинский репозиторий
svnadmin create C:\lab2svn\repo

# Делаем гадость-сладость чтобы можно было менять автора при ошибке (не понадобилось, но на всякий оставлю)
# Ну т.е. ставим хук
# Чтобы не забыть и не нагадить на защите: @''@ - записть многострочного текста без интерпретации переменных
# То что внутри - содержание .bat файла, который просто делает нам жоский exit 0 - то есть, как раз, дает добро на изменения автора 
# На stackwoerflow написано что UTF может вызвать конфликты для таких файлов, поэтому от греха подальше используем ASCII. Он добри)
# Вот этот самый pre-revprop-change.bat - запускается перед изменением revision property (то есть автор, дата, логи и тп...).
# svn по умолчанию эту радость запрещает, но хук у нас-то возввращает 0, то есть дает добро и позитив.
# Вообще, вроде бы как, это делать гадко для реального проекта, но у нас в целях сдачи лабы и саморазвития - дозволено (ну я надеюсь)
@'
@ECHO OFF
exit 0
'@ | Out-File -FilePath "C:\lab2svn\repo\hooks\pre-revprop-change.bat" -Encoding ASCII

# Без этой строки Мордор падет (не заработают команды для работы с zip)
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Тут вообще пойдем по той же технологии, что мы с Марком придумали для git-сценария.
# В svn решили выпендриться (или в гите, хз) и вместо master тут trunk. В нашем случае мы все равно ее превратим в line1)))

#Все тоже самое, что в гите, только еще добавили новый параметр целевой директории из-за особенностей работы svn
function Extract-Commit {
    param ([int]$N, [string]$DestDir)
    
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    
    $zip = [System.IO.Compression.ZipFile]::OpenRead("C:\opiCommits\commit$N.zip")
    foreach ($e in $zip.Entries) {
        if ([string]::IsNullOrEmpty($e.Name)) { continue }
        $name = if ($e.Name -eq '*') { '_' } else { $e.FullName }
        $target = Join-Path $DestDir $name
        $targetDir = Split-Path $target -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
    }
    $zip.Dispose()
}

function Check-Commit-Content {
    param ([int]$N)
    $zip = [System.IO.Compression.ZipFile]::OpenRead("C:\opiCommits\commit$N.zip")
    $zip.Entries | ForEach-Object { "{0,10} {1}" -f $_.Length, $_.FullName }
    $zip.Dispose()
}


#========== Commit 0 ==========

# SVN в отличии от git гаденыш противный, а потому ему нельзя напрямую залить спокойненько файлы из zip. Потому сначала разархивируем
# В временную папку и только потом импортируем
$tempdir = "C:\lab2svn\temp_import"
New-Item -Itemtype Directory -Path $tempdir -Force
# Сюда выжимаем соки нашего архива commit0.zip
Extract-Commit -N 0 -DestDir $tempDir
# Проверка на всякий случаей, что все вылезло в temp_import
Get-ChildItem $tempDir
# Теперь уже вкусняшку импортируем в репу. Нулевой коммит у нас r0 -красный, поэтому юзер тоже красни
# Это чудо-технология подписывает вместо хэша комиты как в ТЗ лабы, только вот отсчет начинается с r1. Поэтому
# Тут критически важно указывать какой это r на самом деле

# Кстати еще момент. Тут маленько потерялся с "///". Сразу тут поясню чтобы не забыть
# Ссылка на репу - URL, то есть как в браузере, только URL для локальной машины. Хоста нет - значит ничего и не пишем, но слеш все же нужен
# Потому и лишний '/' в file:///...

# А пояснялка по "file:" - svn для работы по сети, а потому ему нужен URL, а URL нужна схема. Для локальной работы как file подходит.
svn import C:\lab2svn\temp_import\ file:///C:/lab2svn/repo/trunk -m "r0: initial commit" --username red
# После инициализирующего импорта это чудище может создать рабочую копию wc
# Поэтому в услугах временной папки более не нуждаемся и удаляем ее
Remove-Item -Recurse -Force C:\lab2svn\temp_import\
#Вот и подтягиваем свеженькие данные из repo в свежую рабочую копию wc
# В последствии можно будет пользоваться update - оно просто заливает последнюю ревизию в уже существующую рабочую копию.
# И да, просто так, вручную ее не создать (ну я имею ввиду проводник), поскольку при checkout svn в папку добавляет все необходимые метаданные в скрытую директорию .svn
svn checkout file:///C:/lab2svn/repo C:\lab2svn\wc_trunk
# Смотрим саму репу, чтобы и там нужные данные уже были и чтобы они были в trunk aKa master/main
svn list -R file:///C:/lab2svn/repo
# Проверяем чтобы юз был красным и что коммент сохранился
svn log file:///C:/lab2svn/repo

# ВАЖНО ОЧЕНЬ ВАЖНО: Я с Марком выбрал стратегию, чтобы мы заместо switch будем пользоваться несколькими wc для симуляции веток.
# Нам покалось это логичнее, так как по сути, в реальности с svn работает несколько людей и у каждого из них есть своя wc, ну вот и сделаем для каждой ветки по wc.
# Просто сделаем вид, что все разрабы за одним компом сидят, потому все wc находятся в одной директории)))

#========== Commit 1 ==========

# Делаем ветку line2 в репе. Увы это он поять за ревизию посчитает, потому эта копия (не готовый коммит по заданию) уже получит r2, а сам коммит будет r3 (для svn)
svn copy file:///C:/lab2svn/repo/trunk file:///C:/lab2svn/repo/branches/line2 --parents -m "r1: branch line2 from line1" --username blue

# Делаем wc для line2
svn checkout file:///C:/lab2svn/repo/branches/line2 C:\lab2svn\wc_line2
#Чистим от мусора и закидываем уже нужное. Про функцию Extract_Commit можно почитать в .sh для гита
Get-ChildItem C:\lab2svn\wc_line2 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 1 -DestDir C:\lab2svn\wc_line2
# Глянем что распаковалось. Убедимся что проблемный '*' файл обработался корректно
Get-ChildItem C:\lab2svn\wc_line2
cd C:\lab2svn\wc_line2
# Добавляем все к коммиту. Кстати этот идиот не способен обработать удаленные файлы, поэтому надо дополнительно помогать ему
# --force тут нужен, поскольку svn уже следит за папкой после чекаута, но не ожидает, что я сюда новые файлы так то закидывать буду. Поэтому принудительно заставляю
# ... его пересмотреть свои принципы и начать отслеживать залитый свежачок (файлы из commit1.zip)
svn add --force .
# Смотрим что этот олух потерял. (Посмотрели, ничего не потерял, оставляем svn status ванильным)
svn status 
# Все крута, коммитим
svn commit -m "r1: commit on line2" --username blue

#========== Commit 2 ==========
svn copy file:///C:/lab2svn/repo/branches/line2 file:///C:/lab2svn/repo/branches/line3 -m "r2: branch line3 from line2" --username red
svn checkout file:///C:/lab2svn/repo/branches/line3 C:\lab2svn\wc_line3
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
cd C:\lab2svn\wc_line3
Extract-Commit -N 2 -DestDir C:\lab2svn\wc_line3
svn add --force .
# Вот тут у нас некотрые файлы при коммите пропали, поэтому добавляем приколюху на автоудаление пропавших файлов. Их удобно ловить по спецсимволу !
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r2: commit on line3" --username red
# Я тут попался на ошибки и написал svn log. Он не рассказал про r5. Сразу объясняю, все потому что он пишет логи только для директории, где...
# ...я svn log и написал, то есть для wc_line3. Для нее все актуально вплоть до checkout (r4), r5 - не ее забота уже, потому и не указало.
svn log file:///C:/lab2svn/repo

#========== Commit 3 ==========
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 3 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r3: commit on line3" --username red
svn log file:///C:/lab2svn/repo

#========== Commit 4 ==========
svn copy file:///C:/lab2svn/repo/branches/line3 file:///C:/lab2svn/repo/branches/line4 -m "r4: branch line4 from line3" --username blue
svn checkout file:///C:/lab2svn/repo/branches/line4 C:\lab2svn\wc_line4
Get-ChildItem C:\lab2svn\wc_line4 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
cd C:\lab2svn\wc_line4
Extract-Commit -N 4 -DestDir C:\lab2svn\wc_line4
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r4: commit on line4" --username blue
svn log file:///C:/lab2svn/repo

#========== Commit 5 ==========
# Тут исходя из опыта работы с зипками в git я помню, что файлы commit4.zip = commit5.zip = commit6.zip
# Воспользуюсь тем, что svn обозначает копию (aKa создание новой ветки) ревизией и просто скопирую, не внося данные из commit5.zip и commit6.zip.
# Еще и юзера отметить можно, идеально)))

svn copy file:///C:/lab2svn/repo/branches/line4 file:///C:/lab2svn/repo/branches/line5 -m "r5: branch line5 from line4" --username red
svn checkout file:///C:/lab2svn/repo/branches/line5 C:\lab2svn\wc_line5
# Буду теперь еще лимит вешать, а то мусора много. Все равно он пишет ревизии от младшей к старшей
svn log file:///C:/lab2svn/repo --limit 5
#========== Commit 6 ==========

svn copy file:///C:/lab2svn/repo/branches/line5 file:///C:/lab2svn/repo/branches/line6 -m "r6: branch line6 from line5" --username red
svn checkout file:///C:/lab2svn/repo/branches/line6 C:\lab2svn\wc_line6
svn log file:///C:/lab2svn/repo --limit 5

# Щас будут небольшие фиксы для trunk. Там в wc_trunk на моем локальном тесте появилась поддиректория trunk, которая от скрипта может и не появиться. Она по факту лишняя...
# ...На всякий напишу сюда скрипт починки этого недоразумения, все равно он не повредит даже если все хорошо.

Remove-Item -Recurse -Force C:\lab2svn\wc_trunk
svn checkout file:///C:/lab2svn/repo/trunk C:\lab2svn\wc_trunk
# На всяк логнем
Get-ChildItem C:\lab2svn\wc_trunk

#========== Commit 7 ==========
Get-ChildItem C:\lab2svn\wc_trunk -Force -Exclude ".svn" | Remove-Item -Recurse -Force
cd C:\lab2svn\wc_trunk
Extract-Commit -N 7 -DestDir C:\lab2svn\wc_trunk
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r7: commit on line1" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 8 ==========
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
cd C:\lab2svn\wc_line3
Extract-Commit -N 8 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r8: commit on line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 9 ==========
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 9 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r9: commit on line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 10 ==========
svn copy file:///C:/lab2svn/repo/branches/line3 file:///C:/lab2svn/repo/branches/line7 -m "r10: branch line7 from line3" --username red
svn checkout file:///C:/lab2svn/repo/branches/line7 C:\lab2svn\wc_line7
Get-ChildItem C:\lab2svn\wc_line7 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
cd C:\lab2svn\wc_line7
Extract-Commit -N 10 -DestDir C:\lab2svn\wc_line7
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r10: commit on line7" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 11 ==========
# Тут кстати тоже идентичное содержание commit10.zip - потому просто делаем ветку, ревизия зафиксируется в логах
svn copy file:///C:/lab2svn/repo/branches/line7 file:///C:/lab2svn/repo/branches/line8 -m "r11: branch line8 from line7" --username blue
svn checkout file:///C:/lab2svn/repo/branches/line8 C:\lab2svn\wc_line8
cd C:\lab2svn\wc_line8
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 12 ==========
Get-ChildItem C:\lab2svn\wc_line8 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 12 -DestDir C:\lab2svn\wc_line8
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r12: commit on line8" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 13 ==========
svn copy file:///C:/lab2svn/repo/branches/line8 file:///C:/lab2svn/repo/branches/line9 -m "r13: branch line9 from line8" --username blue
svn checkout file:///C:/lab2svn/repo/branches/line9 C:\lab2svn\wc_line9
cd C:\lab2svn\wc_line9
Get-ChildItem C:\lab2svn\wc_line9 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 13 -DestDir C:\lab2svn\wc_line9
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r13: commit on line9" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 14 ==========
cd C:\lab2svn\wc_line2
Get-ChildItem C:\lab2svn\wc_line2 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 14 -DestDir C:\lab2svn\wc_line2
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r14: commit on line2" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 15 ==========
cd C:\lab2svn\wc_line8
Get-ChildItem C:\lab2svn\wc_line8 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 15 -DestDir C:\lab2svn\wc_line8
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r15: commit on line8" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 16 ==========
cd C:\lab2svn\wc_line7
Get-ChildItem C:\lab2svn\wc_line7 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 16 -DestDir C:\lab2svn\wc_line7
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r16: commit on line7" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 17 ==========
# Пошло мясо (мердж)
cd C:\lab2svn\wc_line3
# На всякий подтянем в wc_line3 то что в репе лежит. Перестраховка если где-то напакостил
svn update
svn merge file:///C:/lab2svn/repo/branches/line7

# Потестил у себя, все супер. Но надо закинуть все-таки содержимое commit17, так что следующие строки посвящаются:
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 17 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r17: merge line7 into line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 18 ==========
cd C:\lab2svn\wc_trunk
Get-ChildItem C:\lab2svn\wc_trunk -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 18 -DestDir C:\lab2svn\wc_trunk
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r18: commit on line1" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 19 ==========
cd C:\lab2svn\wc_line4
Get-ChildItem C:\lab2svn\wc_line4 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 19 -DestDir C:\lab2svn\wc_line4
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r19: commit on line4" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 20 ==========
cd C:\lab2svn\wc_line6
Get-ChildItem C:\lab2svn\wc_line6 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 20 -DestDir C:\lab2svn\wc_line6
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r20: commit on line6" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 21 ==========
cd C:\lab2svn\wc_line9
Get-ChildItem C:\lab2svn\wc_line9 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 21 -DestDir C:\lab2svn\wc_line9
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r21: commit on line9" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 22 ==========
cd C:\lab2svn\wc_trunk
Get-ChildItem C:\lab2svn\wc_trunk -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 22 -DestDir C:\lab2svn\wc_trunk
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r22: commit on line1" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 23 ==========
cd C:\lab2svn\wc_line8
Get-ChildItem C:\lab2svn\wc_line8 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 23 -DestDir C:\lab2svn\wc_line8
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r23: commit on line8" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 24 ==========
# Еще мердж
cd C:\lab2svn\wc_line6
svn update
svn merge file:///C:/lab2svn/repo/branches/line8
# Тут бубенит аж три диапазона мерджа (я про команду снизу). Но вроде все норм, результат адекватный, конфликтов не видно (либо я слепой)
svn status
Get-ChildItem C:\lab2svn\wc_line6 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 24 -DestDir C:\lab2svn\wc_line6
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r24: merge line8 into line6" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 25 ==========
cd C:\lab2svn\wc_line9
Get-ChildItem C:\lab2svn\wc_line9 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 25 -DestDir C:\lab2svn\wc_line9
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r25: commit on line9" --username blue
svn log file:///C:/lab2svn/repo --limit 5


#========== Commit 26 ==========
cd C:\lab2svn\wc_line6
Get-ChildItem C:\lab2svn\wc_line6 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 26 -DestDir C:\lab2svn\wc_line6
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r26: commit on line6" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 27 ==========
Get-ChildItem C:\lab2svn\wc_line6 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 27 -DestDir C:\lab2svn\wc_line6
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r27: commit on line6" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 28 ==========
# Еще мердж
cd C:\lab2svn\wc_line5
svn update
svn merge file:///C:/lab2svn/repo/branches/line6
svn status
Get-ChildItem C:\lab2svn\wc_line5 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 28 -DestDir C:\lab2svn\wc_line5
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r28: merge line6 into line5" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 29 ==========
cd C:\lab2svn\wc_line3
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 29 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r29: commit on line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 30 ==========
cd C:\lab2svn\wc_line4
Get-ChildItem C:\lab2svn\wc_line4 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 30 -DestDir C:\lab2svn\wc_line4
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r30: commit on line4" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 31 ==========
cd C:\lab2svn\wc_line2
Get-ChildItem C:\lab2svn\wc_line2 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 31 -DestDir C:\lab2svn\wc_line2
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r31: commit on line2" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 32 ==========
# Еще мердж
cd C:\lab2svn\wc_line3
svn update
svn merge file:///C:/lab2svn/repo/branches/line2

#Милльен p чтобы наверняка проскипало все конфилкты. Мы ведь все равно зальем файлы с зипки
# Ошибки в консоли - просто няшный p отработал свое и powershell его читает как командлет. Все норм
p
p
p
p
p
p
p
p
#Почемаем все проблемн как решенные, потому что мы молодцы
# Через --accept working сохраняем то что есть в директории, без этих всяких ours theirs 
svn resolve --accept working -R .
svn status
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 32 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r32: merge line2 into line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 33 ==========
cd C:\lab2svn\wc_line9
Get-ChildItem C:\lab2svn\wc_line9 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 33 -DestDir C:\lab2svn\wc_line9
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r33: commit on line9" --username blue
svn log file:///C:/lab2svn/repo --limit 5


#========== Commit 34 ==========
cd C:\lab2svn\wc_line5
Get-ChildItem C:\lab2svn\wc_line5 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 34 -DestDir C:\lab2svn\wc_line5
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r34: commit on line5" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 35 ==========
cd C:\lab2svn\wc_line3
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 35 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r35: commit on line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 36 ==========
cd C:\lab2svn\wc_line5
Get-ChildItem C:\lab2svn\wc_line5 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 36 -DestDir C:\lab2svn\wc_line5
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r36: commit on line5" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 37 ==========
# Еще мердж
cd C:\lab2svn\wc_line3
svn update
svn merge file:///C:/lab2svn/repo/branches/line5
svn status
# Тут тоже конфликты (ну еще бы). Он только уже понял, что спрашивать бесполезно, а потому обойдемся без миллион p
svn resolve --accept working -R .
svn status
Get-ChildItem C:\lab2svn\wc_line3 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 37 -DestDir C:\lab2svn\wc_line3
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r37: merge line5 into line3" --username red
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 38 ==========
# Еще мердж
cd C:\lab2svn\wc_line9
svn update
svn merge file:///C:/lab2svn/repo/branches/line3
p
p
p
p
svn status
# Тут тоже конфликты (ну еще бы). Он только уже понял, что спрашивать бесполезно, а потому обойдемся без миллион p
svn resolve --accept working -R .
svn status
Get-ChildItem C:\lab2svn\wc_line9 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 38 -DestDir C:\lab2svn\wc_line9
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r38: merge line3 into line9" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 39 ==========
# Еще мердж
cd C:\lab2svn\wc_line4
svn update
svn merge file:///C:/lab2svn/repo/branches/line9
svn status
svn resolve --accept working -R .
svn status
Get-ChildItem C:\lab2svn\wc_line4 -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 39 -DestDir C:\lab2svn\wc_line4
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r39: merge line9 into line4" --username blue
svn log file:///C:/lab2svn/repo --limit 5

#========== Commit 40 ==========
# Еще мердж
cd C:\lab2svn\wc_trunk
svn update
svn merge file:///C:/lab2svn/repo/branches/line4
p
p
p
p
p
svn status
svn resolve --accept working -R .
svn status
Get-ChildItem C:\lab2svn\wc_trunk -Force -Exclude ".svn" | Remove-Item -Recurse -Force
Extract-Commit -N 40 -DestDir C:\lab2svn\wc_trunk
svn add --force .
svn status | Where-Object { $_ -match '^!' } | ForEach-Object { 
    $file = ($_ -split '\s+', 2)[1]
    svn delete $file
}
svn status
svn commit -m "r40: merge line4 into line1. Final commit :D" --username red
svn log file:///C:/lab2svn/repo --limit 5

# УРААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААА

# Лог на отчет фотокарточку няшки милашки
svn log file:///C:/lab2svn/repo