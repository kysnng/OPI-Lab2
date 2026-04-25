cd C:\
Remove-Item -Recurse -Force "C:\lab2"
mkdir "C:\lab2"
cd "C:\lab2"
git init repo
cd repo

#Для себя на время работы: git reset --hard HEAD~1
#Это откат на 1 коммит от HEAD. Если накосячу

# Сразу убираем мусорные предупреждения о смене типа переноса
git config core.autocrlf false

# Бахнем функцию чистки репозитория от мусора (прошлых коммитов). Так избежим лишних ошибок (надеюсб)
function Clear-Repo {
    Get-ChildItem "C:\lab2\repo" -Force -Exclude ".git" | Remove-Item -Recurse -Force
}



function Check-File-Content{
    param ([int]$N)
    $zip = [System.IO.Compression.ZipFile]::OpenRead("C:\opiCommits\commit$N.zip")
    $zip.Entries | ForEach-Object { "{0,10} {1}" -f $_.Length, $_.FullName }
    $zip.Dispose()
}

# Напишем универсальную функцию для распаковки коммита
# Она сразу чекает наличие невалидного '*' и переименовывает его. Такая проблема встретилась в r1.
function Extract-Commit {
    # Задаем параметр, чтобы можно было указать номер коммита. Архивы все равно только циферкой отличаются
    param ([int]$N)
    # Для начала просто системными методами откроем архив, чтобы получить доступ к содержимому
    $zip = [System.IO.Compression.ZipFile]::OpenRead("C:\opiCommits\commit$N.zip")
    foreach ($e in $zip.Entries) {
    # Собственнно, сам пропуск папок. Их система видит как файлы с пустым именем. С помощью этого и скипаем их
    if ([string]::IsNullOrEmpty($e.Name)) { continue }
    # Тут смотрим чтобы не было в названии гадости - '*'. Если есть меняем на не гадост - '_'
    # Если все норм с названием присваиваем переменной полное имя файла
    $name = if ($e.Name -eq '*') { '_' } else { $e.FullName }
    # Не спеша, без суеты, словно особый ритуал распаковываем файлы в цикле в repo
    # Без Join-Path хлопчик на OC путается и не хочет никуда закидывать, так что используем его,ну и на всякий разрешаем менять файлы, если они уже есть в repo
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path "C:\lab2\repo" $name), $true)
}
    # Закрываем чтение архива от греха подальше
    $zip.Dispose()
}

# Лллллогирование
function Check-Logs {
    # Наблюдаем за корректностью ведения веток по заданию.
    # Кстати запомнить интересный прикол. Использую %D вместо %d потому что %D пишет красиво без лишних пробелов и скобок. Не знал такого раньше
    # --all Тут делает так, чтобы было все ветки
    # --graph Тут делает так, чтобы в powershell можно было визуально (очень позорно правда) увидеть граф веток
    git log --pretty=format:"%h | %D | %an | %s" --all --graph
}


# Для преподавателя: Функция с каждой новой проблемой дорабатывается.
# Чтобы найти откуда взялось то или иное нужно смотреть по самим коммитам. Я в комментах пишу о появившихся проблемах и их решении
# Тут уже функция которая решает большинство проблем сразу, потому такая сладость в DefCommit)
function DefCommit-Red {
    param ([int]$N)
    git config user.name "red"
    git config user.email "markBaka@gmail.com"
    git add -A
    git commit --allow-empty -m "r$N"
}

function DefCommit-Blue {
    param ([int]$N)
    git config user.name "blue"
    git config user.email "solodd1900@gmail.com"
    git add -A
    git commit --allow-empty -m "r$N"
}

#========== Commit 0 ==========

# Распаковываем архив с r0 и кидаем в repo
Extract-Commit 0
# Задаем имя пользователя по ветке коммита
DefCommit-Red 0
# Переименовываем ветку master в line1. Выбрал такие названия, потому что так проще всего ориентироваться, ну и у меня особо фантазии не хватило)))
git branch -M line1
# Смотрим логи чтобы было все супир)))
Check-Logs

#========== Commit 1 ========== (нет это не коммент клауда, просто '=' очень уж хорошо выполняет роль разделителя)

# Шлепаем на синюю ветку. Будет у нас величаться line2. 
git checkout -b line2
# Чистит repo после коммита, исключая из отчистки папку .git
Clear-Repo
# ПРОБЛЕМА r1: Тут есть проблема - файл с названием "*". Архиватор Windows...
# ...не справляется с распаковкой архива с таким файлом. Поэтому необходимо его переименовать внутри архива на валидное имя
# Но мы аранее позаботились об этом и используем предопределенную для таких случаев функцию
Extract-Commit 1 
DefCommit-Blue 1
Check-Logs

#========== Commit 2 ==========
git checkout -b line3
Clear-Repo
Extract-Commit 2
DefCommit-Red 2
Check-Logs

#========== Commit 3 ==========

# РЕШЕННАЯ ПРОБЛЕМА: Тут снова пакость в виде '*'. Благо мы умные и уже имеем решающую данную проблему функцию.

Clear-Repo
Extract-Commit 3
DefCommit-Red 3
Check-Logs

#========== Commit 4 ==========

git checkout -b line4
Clear-Repo
Extract-Commit 4
DefCommit-Blue 4
Check-Logs

#========== Commit 5 ==========
# ПРОБЛЕМА: содержимое commit5.zip ничем не отличается от commit4.zip
# Решаем тем, что добавляем флаг --allow-empty в коммит

git checkout -b line5
Clear-Repo
Extract-Commit 5
DefCommit-Red 5
Check-Logs

#========== Commit 6 ==========
# Ну либо я тупой, либо реально прикол такой. Тут тоже нет изменений. --allow-empty заролял.
git checkout -b line6
Clear-Repo
Extract-Commit 6
DefCommit-Red 6
Check-Logs

#========== Commit 7 ==========
#Возвращаемся в родную line1
# Наконец-то появился смысл в --all и --graph для Chech-Logs
git checkout line1
Clear-Repo
Extract-Commit 7
DefCommit-Red 7
Check-Logs

#========== Commit 8 ==========

git checkout line3
Clear-Repo
Extract-Commit 8
DefCommit-Red 8
Check-Logs

#========== Commit 9 ==========
Clear-Repo
Extract-Commit 9
DefCommit-Red 9
Check-Logs

#========== Commit 10 ==========
git checkout -b line7
Clear-Repo
Extract-Commit 10
DefCommit-Red 10
Check-Logs

#========== Commit 11 ==========
git checkout -b line8
Clear-Repo
Extract-Commit 11
DefCommit-Blue 11
Check-Logs

#========== Commit 12 ==========
Clear-Repo
Extract-Commit 12
DefCommit-Blue 12
Check-Logs

#========== Commit 13 ==========
git checkout -b line9
Clear-Repo
Extract-Commit 13
DefCommit-Blue 13
Check-Logs

#========== Commit 14 ==========
git checkout line2
Clear-Repo
Extract-Commit 14
DefCommit-Blue 14
Check-Logs

#========== Commit 15 ==========
git checkout line8
Clear-Repo
Extract-Commit 15
DefCommit-Blue 15
Check-Logs

#========== Commit 16 ==========
git checkout line7
Clear-Repo
Extract-Commit 16
DefCommit-Red 16
Check-Logs

#========== Commit 17 ==========
# Первый мердж. Делаем
git checkout line3
# Пока просто готовим мердж, поэтому --no-commit (у нас же есть commit17.zip все таки). 
# выбрал --strategy=ours чтобы наверняка избежать конфликтов. Один фиг из commit17.zip закинем новые данные
git merge line7 --no-commit --strategy=ours
Clear-Repo
Extract-Commit 17
DefCommit-Red 17
Check-Logs
#Для проверки смотрю еще хэши родителей (по сути должно быть два хэша от r9 и r16, так оно и есть). Просто перестраховался навсяк
# -n 5 написал чтобы не видеть эту гигантскую страхолюдную историю всех коммитов) 
git log --pretty=format:"%h | parents:%p | %D | %an | %s" --all --graph -n 5

#========== Commit 18 ==========
git checkout line1
Clear-Repo
Extract-Commit 18
DefCommit-Red 18
Check-Logs

#========== Commit 19 ==========
git checkout line4
Clear-Repo
Extract-Commit 19
DefCommit-Blue 19
Check-Logs

#========== Commit 20 ==========
git checkout line6
Clear-Repo
Extract-Commit 20
DefCommit-Red 20
Check-Logs