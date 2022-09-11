# `Подготовительные операции`

### `Создаем таблицы`

![Альт-текст](https://i.ibb.co/b6ybM1j/Home-Work10-1.png)

![Альт-текст](https://i.ibb.co/3d8Z8GK/Home-Work10-2.png)

Таблицы созданы

`select * from pg_tables t where t.schemaname ='public';`

![Альт-текст](https://i.ibb.co/kh1G38B/Home-Work10-3.png)

При этом неявно созданы индексы для ПК

`select * from pg_indexes i where i.schemaname ='public';`

![Альт-текст](https://i.ibb.co/mtKdF2r/Home-Work10-4.png)

### `Заполняем таблицы данными`

![Альт-текст](https://i.ibb.co/9vDtN6r/Home-Work10-5.png)

![Альт-текст](https://i.ibb.co/DMwKrBn/Home-Work10-6.png)

![Альт-текст](https://i.ibb.co/b1C0KqF/Home-Work10-7.png)

### `Актуализируем статистику`

![Альт-текст](https://i.ibb.co/ZG81ZCj/Home-Work10-8.png)

![Альт-текст](https://i.ibb.co/g4859C6/Home-Work10-9.png)

# `Часть 1 - Индексы`

Использование индекса (ПК)

`explain select brief, full_name from client where client_id = 5000;`

Запрос выполняет поиск записи с использование идекса

![Альт-текст](https://i.ibb.co/HKmfp4V/Home-Work10-10.png)

Поиск записи без использования индекса (сканирование таблицы)

`explain select brief, full_name from client where brief = 'Brief5000';`

![Альт-текст](https://i.ibb.co/2nmsRS0/Home-Work10-11.png)

Создаем индекс для полнотекстового поиска

![Альт-текст](https://i.ibb.co/5nWhvXB/Home-Work10-12.png)

Пример поиска без использования индекса (сканирование таблицы)

`explain select brief, full_name from client where full_name like '%Name%' and full_name like '%5000%';`

![Альт-текст](https://i.ibb.co/k8pGb5N/Home-Work10-13.png)

Пример поиска с использование индекса

`explain select brief, full_name from client where full_name_tsv @@ to_tsquery('Name & 5000');`

![Альт-текст](https://i.ibb.co/By92KQK/Home-Work10-14.png)

Создаем индекс по части таблицы (по дате закрытия, если дата закрытия определена)

![Альт-текст](https://i.ibb.co/zbKp4j8/Home-Work10-15.png)

Пример запроса без использования индекса (сканирование таблицы)

explain select number, close_date from account where close_date is null;

![Альт-текст](https://i.ibb.co/d6jG3G6/Home-Work10-16.png)

Пример запроса с использование индекса

`explain select number, close_date from account where close_date > '20221201';`

* Bitmap Heap Scan on account  (cost=54.79..185.66 rows=2389 width=27)
* Recheck Cond: (close_date > '2022-12-01'::date)
* ->  Bitmap Index Scan on idx_account_closedate  (cost=0.00..54.20 rows=2389 width=0)
* Index Cond: (close_date > '2022-12-01'::date)

Создание составного индекса

![Альт-текст](https://i.ibb.co/CtmcYxR/Home-Work10-17.png)

Использование индекса

explain select client_id from client where is_resident and is_legal;

![Альт-текст](https://i.ibb.co/9y7Jrn7/Home-Work10-18.png)

Индекс включает все информацию по ИД клиента, поэтому запрос целиком обрабатывается
поиском по индексу без обращения к таблице, что значительно ускоряет поиск.

# `Часть 2 - Соединения`

`select c.full_name, a.number from client c inner join account a on a.client_id = c.client_id where c.client_id = 5000;`

![Альт-текст](https://i.ibb.co/F7wPLTf/Home-Work10-19.png)

![Альт-текст](https://i.ibb.co/nsGbfqP/Home-Work10-20.png)

По полю client_id в таблице client индекс есть, поэтому выполняется поиск по индексу.
По полю client_id в таблице account индекса нет, поэтому выполняется последовательное сканирование.
Исправим это.

![Альт-текст](https://i.ibb.co/n6Zn6xW/Home-Work10-21.png)

![Альт-текст](https://i.ibb.co/ZxB9wj2/Home-Work10-22.png)

Так гораздо лучше

Добавим клиента для которого гарантированно еще нет счета

![Альт-текст](https://i.ibb.co/hmGXkCz/Home-Work10-23.png)

Левостороннее соединение таблиц

`select c.full_name, a.number from client c left join account a on a.client_id = c.client_id
where c.client_id = 10001;`

![Альт-текст](https://i.ibb.co/nz43Lrh/Home-Work10-24.png)

Запрос возвращает все записи левой таблицы (client) и имеющиеся соответствующие им записи правой (account) или null.

Правостороннее соединение таблиц

`select a.number, c.full_name from account a right join client c on c.client_id = a.client_id
where c.client_id = 10001;`

![Альт-текст](https://i.ibb.co/ky04q7j/Home-Work10-25.png)

Аналогично, с точностью до наоборот - запрос возвращает все запииси правой таблицы и имеющиеся записи левой.

Кросс соединение двух таблиц (декартово произведение)

`select c.full_name, a.number from client c cross join account a limit 10;`

![Альт-текст](https://i.ibb.co/xFX1tTw/Home-Work10-26.png)

Запрос соединяет все записи левой таблицы со всеми записями правой.

Полное соединение двух таблиц

`select c.full_name, a.number from client c full join account a on c.client_id = a.client_id
where c.client_id in (5000, 10001);`

![Альт-текст](https://i.ibb.co/GdqvRFr/Home-Work10-27.png)

В общем случае, запрос соединяет соответствующие записи левой и правой таблицы и дополняет выборку
недостающими записями левой (для правой возращается null) и недостающими записями правой
(для левой возвращается null).

В данном случае, для каждого счета есть клиент, поэтому в
выборке не будет, где есть номер счета, но не клиета.
