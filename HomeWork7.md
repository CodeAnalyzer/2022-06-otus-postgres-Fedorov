Создать учебную ВМ

![Альт-текст](https://i.ibb.co/f9k56x2/Home-Work7-1.png)

Установить Postgres 14

![Альт-текст](https://i.ibb.co/pnMm0SC/Home-Work7-2.png)

`НАСТРОИТЬ ВЫПОЛНЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ РАЗ В 30 СЕКУНД.`

В postgresql.conf следует изменить настройку checkpoint_timeout (integer)  - _Максимальное время между автоматическими контрольными точками в WAL. Допускаются значения от 30 секунд до одного дня. Значение по умолчанию — пять минут (5min). Увеличение этого параметра может привести к увеличению времени, которое потребуется для восстановления после сбоя._

Кроме того следует включить логирование контрольных точек (log_checkpoints).

**_ssh -i C:\Users\Александр\codeanalyzer otus@51.250.17.195_**

**_sudo nano /etc/postgresql/14/main/postgresql.conf_**

* checkpoint_timeout = 30;
* log_checkpoints = on;

![Альт-текст](https://i.ibb.co/mtMRS6J/Home-Work7-3.png)

![Альт-текст](https://i.ibb.co/s5W6vs3/Home-Work7-4.png)

Рестартовать кластер

**_sudo pg_ctlcluster 14 main restart_**

`10 МИНУТ C ПОМОЩЬЮ УТИЛИТЫ PGBENCH ПОДАВАТЬ НАГРУЗКУ.`

Подготовка теста

**_sudo -u postgres pgbench -i postgres_**

Количество КТ до запуска

**_sudo -u postgres psql_**

**_select checkpoints_timed from pg_stat_bgwriter;_**

Коммит синхронный?

**_show synchronous_commit;_**

Запуск теста

**_sudo -u postgres pgbench --client=8 --progress=60 --time=600 --username=postgres postgres_**

![Альт-текст](https://i.ibb.co/6bcXjyM/Home-Work7-5.png)

`ИЗМЕРИТЬ, КАКОЙ ОБЪЕМ ЖУРНАЛЬНЫХ ФАЙЛОВ БЫЛ СГЕНЕРИРОВАН ЗА ЭТО ВРЕМЯ.`

Количество КТ после запуска

**_sudo -u postgres psql_**

**_select checkpoints_timed from pg_stat_bgwriter;_**

Посчитать разницу - выяснить сколько КТ выполнено: **41 - 14 = 27**

Созданные WAL-файлы

**_select * from pg_ls_waldir();_**

![Альт-текст](https://i.ibb.co/fxqkhZT/Home-Work7-6.png)

`ОЦЕНИТЬ, КАКОЙ ОБЪЕМ ПРИХОДИТСЯ В СРЕДНЕМ НА ОДНУ КОНТРОЛЬНУЮ ТОЧКУ.`

(сумма журнальных файлов) / (количество КТ)

**67108864 / (41 - 14) = 2485513 байт/КТ**

`ПРОВЕРИТЬ ДАННЫЕ СТАТИСТИКИ: ВСЕ ЛИ КОНТРОЛЬНЫЕ ТОЧКИ ВЫПОЛНЯЛИСЬ ТОЧНО ПО РАСПИСАНИЮ.`

sudo tail -n 100 /var/log/postgresql/postgresql-14-main.log | grep checkpoint

![Альт-текст](https://i.ibb.co/vYpBBmP/Home-Work7-7.png)

`ПОЧЕМУ ТАК ПРОИЗОШЛО?`


`СРАВНИТЕ TPS В СИНХРОННОМ/АСИНХРОННОМ РЕЖИМЕ УТИЛИТОЙ PGBENCH. ОБЪЯСНИТЕ ПОЛУЧЕННЫЙ РЕЗУЛЬТАТ.`

Включить асинхронный режим

**_sudo nano /etc/postgresql/14/main/postgresql.conf_**

**_synchronous_commit = off_**

![Альт-текст](https://i.ibb.co/Xkw9K3T/Home-Work7-8.png)

Рестартовать кластер

**_sudo pg_ctlcluster 14 main restart_**

Подготовка теста

**_sudo -u postgres pgbench -i postgres_**

Коммит aсинхронный?

**_sudo -u postgres psql_**

**_show synchronous_commit;_**

Запуск теста

**_sudo -u postgres pgbench --client=8 --progress=60 --time=600 --username=postgres postgres_**

![Альт-текст](https://i.ibb.co/vQ88s8T/Home-Work7-9.png)

Объяснение

В асинхронном режим сервер не дожидается окончания записи WAL на диске.

https://postgrespro.ru/docs/postgresql/14/runtime-config-wal

_Определяет, после завершения какого уровня обработки WAL сервер будет сообщать об успешном выполнении операции. Допустимые значения: remote_apply (применено удалённо), on (вкл., по умолчанию), remote_write (записано удалённо), local (локально) и off (выкл.). Локальное действие всех отличных от off режимов заключается в ожидании локального сброса WAL на диск._

`СОЗДАЙТЕ НОВЫЙ КЛАСТЕР С ВКЛЮЧЕННОЙ КОНТРОЛЬНОЙ СУММОЙ СТРАНИЦ.`

Остановить текущий кластер

**_sudo pg_ctlcluster 14 main stop_**

Создать новый кластер с включенной контрольной суммой страниц

**_sudo pg_createcluster 14 mycluster -- --data-checksums_**

Порт **5433**

Запустил новый кластер:

**_sudo pg_ctlcluster 14 mycluster start_**

Подключиться и проверить настройку:

**_sudo -u postgres psql -p 5433_**

**_show data_checksums;_**

![Альт-текст](https://i.ibb.co/5BSjbxF/Home-Work7-10.png)

`СОЗДАЙТЕ ТАБЛИЦУ. ВСТАВЬТЕ НЕСКОЛЬКО ЗНАЧЕНИЙ.`

**_create table test (id integer primary key, value text);_**

**_insert into test (id, value) values (1, 'ODIN'), (2, 'DVA');_**

**_select * from test;_**

**_select pg_relation_filepath('test ');_**

![Альт-текст](https://i.ibb.co/c6qJjtY/Home-Work7-11.png)

`ВЫКЛЮЧИТЕ КЛАСТЕР. ИЗМЕНИТЕ ПАРУ БАЙТ В ТАБЛИЦЕ. ВКЛЮЧИТЕ КЛАСТЕР И СДЕЛАЙТЕ ВЫБОРКУ ИЗ ТАБЛИЦЫ.`

**_sudo pg_ctlcluster 14 mycluster stop_**

Изменить файл найденный ранее

![Альт-текст](https://i.ibb.co/58pX3dX/Home-Work7-12.png)

Удалил 4 байта.

![Альт-текст](https://i.ibb.co/mB0P2dK/Home-Work7-13.png)

Запуск кластера:

**_sudo pg_ctlcluster 14 mycluster start;_**

Проверяем данные в таблице:

**_select * from test;_**

![Альт-текст](https://i.ibb.co/23nz5Jj/Home-Work7-14.png)

`ЧТО И ПОЧЕМУ ПРОИЗОШЛО? КАК ПРОИГНОРИРОВАТЬ ОШИБКУ И ПРОДОЛЖИТЬ РАБОТУ?`

Предполагал, что возникнет ошибка с контрольной суммой, но воспроизвести ее не удалось, хотя удалил из файла 4 байта.

См. https://postgrespro.ru/docs/postgresql/14/runtime-config-developer

_При обнаружении ошибок контрольных сумм при чтении PostgreSQL обычно сообщает об ошибке и прерывает текущую транзакцию.
Если параметр ignore_checksum_failure включён, система игнорирует проблему (но всё же предупреждает о ней) и продолжает обработку._

**_set ignore_checksum_failure = on;_**

**_select * from test;_**
