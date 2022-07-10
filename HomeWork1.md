Учебная ВМ

![Альт-текст](https://i.ibb.co/R32Qd3p/img1.png)

Установка Postgres

![Альт-текст](https://i.ibb.co/9wBScqN/img2.png)

pg_lsclusters

![Альт-текст](https://i.ibb.co/MCCDJDZ/img3.png)

Пароль на postgres

![Альт-текст](https://i.ibb.co/hX6jv8M/img4.png)

Добавить сетевые правила для подключения к Postgres:

![Альт-текст](https://i.ibb.co/LpXwg47/img5.png)

![Альт-текст](https://i.ibb.co/yB19JZT/img6.png)

Подключение

![Альт-текст](https://i.ibb.co/ssSd7fC/img7.png)

сделать в первой сессии новую таблицу и наполнить ее данными
create table persons(id serial, first_name text, second_name text);
insert into persons(first_name, second_name) values('ivan', 'ivanov');
insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
посмотреть текущий уровень изоляции

![Альт-текст](https://i.ibb.co/8cmZy9W/img9.png)

начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');
сделать select * from persons; во второй сессии
- видите ли вы новую запись и если да то почему?
НЕТ, уровень изоляции Read Сommitted не позволяет выполнять "грязное чтение" незафиксированных данных

завершить первую транзакцию - commit;
- видите ли вы новую запись и если да то почему?
ДА, после фиксации транзакции запись начинают видеть другие транзакции

![Альт-текст](https://i.ibb.co/8bLZ0mv/img10.png)

начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;
BEGIN ISOLATION LEVEL REPEATABLE READ;
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');
сделать select * from persons во второй сессии
- видите ли вы новую запись и если да то почему?
НЕТ, уровень изоляции Repeatable Read более строгий чем Read Сommitted
он также не позволяет выполнять "грязное чтение" незафиксированных данных.

завершить первую транзакцию - commit;
сделать select * from persons во второй сессии
- видите ли вы новую запись и если да то почему?
НЕТ, на уровне Repeatable Read видим снимок базы сделанный на момент начала транзакции. 
На тот момент новой записи, добавленной первой транзакцией, еще не было. 

завершить вторую транзакцию
сделать select * from persons во второй сессии
- видите ли вы новую запись и если да то почему?
ДА, после фиксации вторая видит все записи зафиксированные всеми предыдущими транзакциями. 

![Альт-текст](https://i.ibb.co/1sKQz7g/img11.png)



