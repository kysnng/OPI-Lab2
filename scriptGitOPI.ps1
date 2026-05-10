cd "C:\lab2"
git init repo
cd repo

#Для себя на время работы: git reset --hard HEAD~1
#Это откат на 1 коммит от HEAD. Если накосячу

# Без этой строки Альбион падет (не заработают команды работы с ZipFile)
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

# Без конфликтов, Fast-Forward

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

#========== Commit 21 ==========
git checkout line9
Clear-Repo
Extract-Commit 21
DefCommit-Blue 21
Check-Logs

#========== Commit 22 ==========
git checkout line1
Clear-Repo
Extract-Commit 22
DefCommit-Red 22
Check-Logs

#========== Commit 23 ==========
git checkout line8
Clear-Repo
Extract-Commit 23
DefCommit-Blue 23
Check-Logs

#========== Commit 24 ==========
# Мердж: line8 в line6
git checkout line6
git merge line8 --no-commit --strategy=ours
Clear-Repo
Extract-Commit 24
DefCommit-Red 24
Check-Logs

#========== Commit 25 ==========
git checkout line9
Clear-Repo
Extract-Commit 25
DefCommit-Blue 25
Check-Logs

#========== Commit 26 ==========
git checkout line6
Clear-Repo
Extract-Commit 26
DefCommit-Red 26
Check-Logs

#========== Commit 27 ==========
Clear-Repo
Extract-Commit 27
DefCommit-Red 27
Check-Logs

#========== Commit 28 ==========

#Без конфликтов, автомердж сработал нормально

# Мердж: line6 в line5 (merge(r27, r5))
git checkout line5
git merge line6 --no-commit --strategy=ours
Clear-Repo
Extract-Commit 28
DefCommit-Red 28
Check-Logs

#========== Commit 29 ==========
git checkout line3
Clear-Repo
Extract-Commit 29
DefCommit-Red 29
Check-Logs

#========== Commit 30 ==========
git checkout line4
Clear-Repo
Extract-Commit 30
DefCommit-Blue 30
Check-Logs

#========== Commit 31 ==========
git checkout line2
Clear-Repo
Extract-Commit 31
DefCommit-Blue 31
Check-Logs

#========== Commit 32 ==========

# !!!!!!!!!Мердж: line2 в line3 (merge(r31, r29))!!!!!!!!!!!

# !!!!!!!!!!!!!!!!!!!!!!! КОНФЛИКТ!!!!!!!!!!!!!!!!!!!!!!!!!!
# Конфликтные файлы: A.java и I.java
# Конфликт заключается в том, что в line3 (HEAD) для A.javaв конце два метода: ll() и aa(). В line2() на кой-то дублируется kk() и снова метод ll().
# Тут максимально взять все что в версии от line3 (ours короче). Чистим ручками метки и добавляем в итоговый merdge-файл методы ll() и aa()

# Для I.java чуть по-другому. В line3 в конце есть новые методы aa() и nn(), в line2 ничего подобного не добавляется.
# Ради прикола решил взять вариант из line2 и просто почистил метку конфликта

git checkout line3
git merge line2 --no-commit
# После фиксов
git add A.java
git add I.java
Clear-Repo
Extract-Commit 32
DefCommit-Red 32
Check-Logs

#========== Commit 33 ==========
git checkout line9
Clear-Repo
Extract-Commit 33
DefCommit-Blue 33
Check-Logs

#========== Commit 34 ==========
git checkout line5
Clear-Repo
Extract-Commit 34
DefCommit-Red 34
Check-Logs

#========== Commit 35 ==========
git checkout line3
Clear-Repo
Extract-Commit 35
DefCommit-Red 35
Check-Logs

#========== Commit 36 ==========
git checkout line5
Clear-Repo
Extract-Commit 36
DefCommit-Red 36
Check-Logs

#========== Commit 37 ==========

# !!!!!!!!!Мердж: line5 в line3 (merge(r36, r35))!!!!!!!!

#!!!!!!!!!!!!!!!!!!!!!! КОНФЛИКТ !!!!!!!!!!!!!!!!

# Конфликты: A.java, E.java. I.java, K.java

# A.java: кароч, первое: тут у HEAD и line5 есть метод kk(), только вот у line5 еще перед ним стоит новый af(). Решил сначала добавить kk(), потом и af() добавил.
# Второе: куча разных неповторящихся методов от HEAD и line5. Взял все неповторяющееся. Также тут есть по-разному определенный hh(), взял его от line5.


# E.java: Ту просто надобавлял все новые методы

#  I.java: Аналогично E.java. aa() был в обеих ветках, просто в разных местах (взял расположение aa() от HEAD)

# K.java: Тут чистый theirs. line5 тупо подробнее делает файл.
git checkout line3
git merge line5 --no-commit
# После фиксов
git add A.java
git add E.java
git add I.java
git add K.java
Clear-Repo
Extract-Commit 37
DefCommit-Red 37
Check-Logs

#========== Commit 38 ==========

# !!!!!!!!!!!Мердж: line3 в line9 (merge(r33, r37))!!!!!!!!!!

# !!!!!!!!!!!!КОНФЛИКТ!!!!!!!!!!!!!!!

#Конфликтные файлы: A.java, I.java, _.java (*)

# A.java: в HEAD версии ничего нет, поэтому фулл theirs.
# I.java: аналогично A.java
# _.java: Тут конфликт в том, что на одной ветке он есть, на другой нет. Нет его как раз в HEAD, поэтому удаляем
git checkout line9
git merge line3 --no-commit
# После фиксов
git add A.java
git add I.java
git rm _.java
Clear-Repo
Extract-Commit 38
DefCommit-Blue 38
Check-Logs

#========== Commit 39 ==========

# Мердж: line9 в line4 (merge(r38, r30))

# !!!!!!!!!!!!КОНФЛИКТ!!!!!!!!!!!!

#Конфликт: A.java, I.java

# A.java: Все точно тоже самое что и в предыдущем мердже. Делаем theirs
# I.java: Опять же, в HEAD пусто, в line9 - нововведения. Theirs

git checkout line4
git merge line9 --no-commit
# После фиксов
git add A.java
git add I.java
Clear-Repo
Extract-Commit 39
DefCommit-Blue 39
Check-Logs

#========== Commit 40 ==========

# Мердж: line4 в line1 (merge(r22, r39))

#!!!!!!!!!!!!Конфиликт!!!!!!!!!!

# Все тоже самое: A.java, I.java. Те же самые фиксы


git checkout line1
git merge line4 --no-commit
# После фиксов
git add A.java
git add I.java
Clear-Repo
Extract-Commit 40
DefCommit-Red 40
Check-Logs

# Финальный взгляд на всю историю
git log --pretty=format:"%h | %D | %an | %s" --all --graph