### `Cделать инстанс ВМ с ОС Ubuntu 20.04`

![Альт-текст](https://i.ibb.co/fqmctDS/Home-Work8-1.png)

Подключение к учебной ВМ

_**ssh -i C:\Users\Александр\codeanalyzer otus@62.84.121.143**_

### `Поставить на нее PostgreSQL 14`

![Альт-текст](https://i.ibb.co/HzP1mGq/Home-Work8-2.png)

### `Установить утилиту sysbench` 

см. https://github.com/akopytov/sysbench

Quick install instructions - Debian/Ubuntu:

**_curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash_**

**_sudo apt -y install sysbench_**

**_sudo apt install git_**

**_git clone https://github.com/Percona-Lab/sysbench-tpcc_**

![Альт-текст](https://i.ibb.co/LY7YFWG/Home-Work8-3.png)

Создать тестовую базу

**_create database perftest;_**

Размер базы до подготовки к тесту

**_select datname, pg_size_pretty(pg_database_size(datname)) as "DB_Size" from pg_stat_database where datname = 'perftest';_**

![Альт-текст](https://i.ibb.co/FqhLx0L/Home-Work8-4.png)

### `Фаза подготовки к тесту`

**_./tpcc.lua --pgsql-user=postgres --pgsql-db=perftest --pgsql-password=12345 --time=120 --report-interval=1 --tables=10 --scale=10 --use_fk=0 --trx_level=RC --db-driver=pgsql prepare_**

![Альт-текст](https://i.ibb.co/rHSyqc7/Home-Work8-5.png)

Размер базы после подготовки к тесту

**_select datname, pg_size_pretty(pg_database_size(datname)) as "DB_Size" from pg_stat_database where datname = 'perftest';_**

![Альт-текст](https://i.ibb.co/mJQQCwc/Home-Work8-6.png)

### `Тест на дефолтных настройках`

**_./tpcc.lua --pgsql-user=postgres --pgsql-db=perftest --pgsql-password=12345 --time=600 --report-interval=1 --tables=10 --scale=10 --use_fk=0 --trx_level=RC --db-driver=pgsql run_**

![Альт-текст](https://i.ibb.co/hBqnxmF/Home-Work8-7.png)

### `Оптимизация настроек`

![Альт-текст](https://i.ibb.co/kBCHky8/Home-Work8-8.png)

Рестарт после изменения

**_sudo pg_ctlcluster 14 main restart_**

### `Тест на оптимизированных настройках`  

**_./tpcc.lua --pgsql-user=postgres --pgsql-db=perftest --pgsql-password=12345 --time=600 --report-interval=1 --tables=10 --scale=10 --use_fk=0 --trx_level=RC --db-driver=pgsql run_**

![Альт-текст](https://i.ibb.co/GFRWjd5/Home-Work8-9.png)

### `Анализ итогов оптимизации`
Сравнивая результаты тестов до и после настройки видим **_существенные_** изменения в производительности.

Количество выполненных запросов выросло с 72тыс. до 884тыс. (в 12+ раз).
Соответственно, скорость выполнения транзакций с 4.25 тр/сек выросла до 51.87 тр/сек.
Аналогичным образом выросли и остальные показатели.

Что было изменено:
* [maintenance_work_mem](https://postgrespro.ru/docs/postgrespro/14/runtime-config-resource#GUC-MAINTENANCE-WORK-MEM) -
_Задаёт максимальный объём памяти для операций обслуживания БД. Увеличение этого значения может привести к ускорению операций очистки и восстановления БД из копии._
* [shared_buffers](https://postgrespro.ru/docs/postgrespro/14/runtime-config-resource#GUC-SHARED-BUFFERS) -
_Задаёт объём памяти, который будет использовать сервер баз данных для буферов в разделяемой памяти. По умолчанию это обычно 128 мегабайт. Однако для хорошей производительности обычно требуются гораздо большие значения._
* [work_mem](https://postgrespro.ru/docs/postgrespro/14/runtime-config-resource#GUC-WORK-MEM) -
_Задаёт базовый максимальный объём памяти, который будет использоваться во внутренних операциях при обработке запросов, прежде чем будут задействованы временные файлы на диске.
В сложных запросах параллельно могут выполняться несколько операций сортировки или хеширования, и при этом примерно этот объём памяти может использоваться в каждой операции, прежде чем данные начнут вытесняться во временные файлы.
Кроме того, такие операции могут выполняться одновременно в разных сеансах._ 
* [checkpoint_timeout](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-CHECKPOINT-TIMEOUT) -
_Максимальное время между автоматическими контрольными точками в WAL.
Увеличение этого параметра приводит к увеличению времени, которое потребуется для восстановления после сбоя,
однако, обеспечивает снижение нагрузки на дисковую подсистему из-за более редкого сохранения КТ._ 
* [min_wal_size](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-MIN-WAL-SIZE) -
_Пока WAL занимает на диске меньше этого объёма, старые файлы WAL в контрольных точках всегда перерабатываются, а не удаляются.
Это может снизить нагрузку на дисковую подсистему за счет уменьшения количества операций создания/удаления файлов._
* [max_wal_size](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-MAX-WAL-SIZE) -
_Общий допустимый объем журнальных файлов. Если фактический объем будет получаться больше, сервер инициирует внеплановую контрольную точку.
Чтобы снизить вероятность запуска сохранения внеплановой КТ, следует увеличить этот параметр._ 
* [bgwriter_lru_maxpages](https://postgrespro.ru/docs/postgrespro/14/runtime-config-resource#GUC-BGWRITER-LRU-MAXPAGES) -
_Задаёт максимальное число буферов, которое сможет записать процесс фоновой записи за раунд активности.
Большее значение ускоряет сохранение буферов и снижает общую нагрузку на дисковую подсистему._
* [bgwriter_lru_multiplier](https://postgrespro.ru/docs/postgrespro/14/runtime-config-resource#GUC-BGWRITER-LRU-MULTIPLIER) -
_Число загрязнённых буферов, записываемых в очередном раунде, зависит от того, сколько новых буферов требовалось серверным процессам в предыдущих раундах.
Средняя недавняя потребность умножается на bgwriter_lru_multiplier и предполагается, что именно столько буферов потребуется на следующем раунде.
Увеличение этого множителя даёт некоторую страховку от резких скачков потребностей._
* [effective_cache_size](https://postgrespro.ru/docs/postgrespro/14/runtime-config-query#GUC-EFFECTIVE-CACHE-SIZE) -
_Определяет представление планировщика об эффективном размере дискового кеша, доступном для одного запроса.
Это представление влияет на оценку стоимости использования индекса; чем выше это значение, тем больше вероятность,
что будет применяться сканирование по индексу, чем ниже, тем более вероятно, что будет выбрано последовательное сканирование._
* [wal_compression](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-WAL-COMPRESSION) -
_Когда этот параметр имеет значение on, сервер Postgres Pro сжимает образ полной страницы, записываемый в WAL.
Этот параметр позволяет без дополнительных рисков повреждения данных уменьшить объём WAL, а, следовательно, снизить нагрузку на дисковую подсистему._
* [fsync](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-FSYNC) -
_Если этот параметр установлен, сервер Postgres Pro старается добиться, чтобы изменения были записаны на диск физически.
Хотя отключение fsync часто даёт выигрыш в скорости, это может привести к неисправимой порче данных в случае отключения питания или сбоя системы.
Поэтому отключать fsync рекомендуется, только если вы легко сможете восстановить всю базу из внешнего источника._
* [full_page_writes](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-FULL-PAGE-WRITES) -
_Когда этот параметр включён, сервер Postgres Pro записывает в WAL всё содержимое каждой страницы при первом изменении этой страницы после контрольной точки.
Это необходимо, потому что запись страницы, прерванная при сбое операционной системы, может выполниться частично, и на диске окажется страница, содержащая смесь старых данных с новыми.
Отключение этого параметра ускоряет обычные операции, но может привести к неисправимому повреждению или незаметной порче данных после сбоя системы.
При этом возникают практически те же риски, что и при отключении fsync, хотя и в меньшей степени._
* [synchronous_commit](https://postgrespro.ru/docs/postgrespro/14/runtime-config-wal#GUC-SYNCHRONOUS-COMMIT) -
_Определяет, после завершения какого уровня обработки WAL сервер будет сообщать об успешном выполнении операции.
Допустимые значения: remote_apply (применено удалённо), on (вкл., по умолчанию), remote_write (записано удалённо), local (локально) и off (выкл.).
Локальное действие всех отличных от off режимов заключается в ожидании локального сброса WAL на диск. В режиме off ожидание отсутствует.
В отличие от fsync, значение off этого параметра не угрожает целостности данных: сбой операционной системы или базы данных может привести
к потере последних транзакций, считавшихся зафиксированными, но состояние базы данных будет точно таким же, как и в случае штатного прерывания этих транзакций._
