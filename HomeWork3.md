Создать Учебную ВМ

![Альт-текст](https://i.ibb.co/mXmP8rt/Homework3-1.png)

Поставить на нее PostgreSQL

Проверить, что кластер запущен

![Альт-текст](https://i.ibb.co/vYM5TcH/Homework3-2.png)

Зайти из-под пользователя postgres в psql

Сделать произвольную таблицу с произвольным содержимым

Остановить postgres

![Альт-текст](https://i.ibb.co/BZ6n3kr/Homework3-3.png)

Создать новый standard persistent диск в том же регионе и зоне, что инстанс

Добавить свежесозданный диск к виртуальной машине

![Альт-текст](https://i.ibb.co/QbbKfgx/Homework3-4.png)

Проинициализировать диск согласно инструкции и подмонтировать файловую систему
https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux

Шаг 1 — Инсталлируем Parted
* sudo apt update
* sudo apt install parted

Шаг 2 — Идентифицируем новый диск в системе
* sudo parted -l | grep Error
* lsblk

Шаг 3 — Партицирование нового диска
Выбираем стандарт разбиения
* sudo parted /dev/sda mklabel gpt
Создаем новую партицию
* sudo parted -a opt /dev/sda mkpart primary ext4 0% 100%
* lsblk

Шаг 4 — Создаем файловую систему в новой партиции
* sudo mkfs.ext4 -L datapartition /dev/sda1

Шаг 5 — Монтирование новой файловой системы
Создаем новый каталог
* sudo mkdir -p /mnt/data
Монтируем в него новый диск (временное монтирование)
* sudo mount -o defaults /dev/sda1 /mnt/data
* df -h -x tmpfs

Можно проверить его работу - содадим файл, выведем его содеримое, затем удалим

* echo "success" | sudo tee /mnt/data/test_file
* cat /mnt/data/test_file
* sudo rm /mnt/data/test_file

![Альт-текст](https://i.ibb.co/b2sLRsv/Homework3-5.png)

Сделать пользователя postgres владельцем /mnt/data

Перенесите содержимое /var/lib/postgres/14 в /mnt/data

Попытаться запустить кластер

![Альт-текст](https://i.ibb.co/68zzvtq/Homework3-6.png)

Написать получилось или нет и почему

_Переместили каталог в котором хранились объекты кластера - табличные пространства, схемы, базы, системные таблицы.
Постгре не может их обнаружить и не инициализирует кластер._

Задание: найти конфигурационный параметр в файлах, расположенных в /etc/postgresql/14/main,
который надо поменять и изменить его

https://pgcookbook.ru/article/database_layout.html

![Альт-текст](https://i.ibb.co/sR2zV9G/Homework3-7.png)

Попытаться запустить кластер, написать получилось или нет и почему

_После изменения конф.файла, Постгре смог обнаружить перемещенный каталог и инициализировал кластер._

![Альт-текст](https://i.ibb.co/JKW8wHc/Homework3-8.png)

Зайти через psql и проверить содержимое ранее созданной таблицы

![Альт-текст](https://i.ibb.co/Js0G523/Homework3-9.png)