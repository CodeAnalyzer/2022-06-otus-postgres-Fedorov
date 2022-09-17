# `Подготовительные операции`

### `База данных`

https://www.postgrespro.ru/education/demodb

Скачиваем demo-medium.zip (62 МБ) — данные по полетам за три месяца (размер БД примерно 700 МБ)

Схема БД

![Альт-текст](https://i.ibb.co/ng18CVk/Home-Work11-1.png)

### `Установка`

_psql -f demo-medium-20170815.sql -U postgres_

![Альт-текст](https://i.ibb.co/GcmDsG2/Home-Work11-2.png)

Самая большая таблица - boarding_passes.

### `Анализ`

select min(bp.flight_id), max(bp.flight_id), count(*)

from bookings.boarding_passes bp

group by bp.flight_id / 10000

order by bp.flight_id / 10000;

![Альт-текст](https://i.ibb.co/W23jWc6/Home-Work11-3.png)

Полагаю, оптимально секционировать эту таблицу по 10000 идентификаторов полетов.

# `Секционирование`

### `Создаем основную таблицу`

_create table board_passes (like boarding_passes including all) partition by range (flight_id);_

### `Создаем внешний ключ`

_alter table bookings.board_passes add constraint board_passes_ticket_no_fkey foreign key (ticket_no, flight_id) references ticket_flights(ticket_no, flight_id);_

### `Создаем секции`

* _create table board_passes_1 partition of board_passes for values from (1) to (10000);_
* _create table board_passes_2 partition of board_passes for values from (10000) to (20000);_
* _create table board_passes_3 partition of board_passes for values from (20000) to (30000);_
* _create table board_passes_4 partition of board_passes for values from (30000) to (40000);_
* _create table board_passes_5 partition of board_passes for values from (40000) to (50000);_
* _create table board_passes_6 partition of board_passes for values from (50000) to (60000);_
* _create table board_passes_7 partition of board_passes for values from (60000) to (70000);_

![Альт-текст](https://i.ibb.co/rGh9bvz/Home-Work11-4.png)

### `Копируем данные`

_insert into bookings.board_passes (ticket_no, flight_id, boarding_no, seat_no)_

_select bp.ticket_no, bp.flight_id, bp.boarding_no, bp.seat_no from bookings.boarding_passes bp;_

Актуализируем статистику

_analyze board_passes;_

![Альт-текст](https://i.ibb.co/5Lcp65V/Home-Work11-5.png)

### `Использование`

_explain (analyze) select ticket_no from board_passes where flight_id < 10000;_

![Альт-текст](https://i.ibb.co/q9yBbVS/Home-Work11-6.png)

Оптимизатор запросов понял, что по условию получим всю секцию board_passes_1 поэтому выполняет последовательное сканирование ее.

_explain (analyze) select ticket_no from boarding_passes where flight_id < 10000;_

![Альт-текст](https://i.ibb.co/rwjT6F8/Home-Work11-7.png)

Оптимизатор запросов решил отобрать записи по индексу затем получить соответсвующие им номера билетов.

Сканирование с использованием битовых карт используется, когда при индексном сканировании нужно выбрать много записей за раз. Recheck Cond, то есть перепроверка условий запроса, может применяться, когда объем  данных в таблице слишком большой, чтобы поддерживать битовую карту в актуальном состоянии.

Как видим, данный запрос выполняется в два раза дольше для несекционированной таблице,
потому что приходится делать выборку изо всей таблице, в которой содержится более 1.8 млн записей.

В запросе из секционированной таблицы выборка происходит из одной секции в 400 тыс. записей,
к тому же запрос выполняет меньше операций с данным, что также влияет на производительность.
