### `Делаем виртуальные машины`

![Альт-текст](https://i.ibb.co/Hq1chTm/Home-Work9-1.png)

Подключение

* ВМ-1	**_ssh -i C:\Users\Александр\codeanalyzer otus@84.252.141.141_**
* ВМ-2	**_ssh -i C:\Users\Александр\codeanalyzer otus@51.250.102.202_**
* ВМ-3	**_ssh -i C:\Users\Александр\codeanalyzer otus@51.250.26.12_**

### `Установиливаем Posgres 14 и настраиваем доступ`

![Альт-текст](https://i.ibb.co/mcvtT1Q/Home-Work9-2.png)

![Альт-текст](https://i.ibb.co/pXwwKkw/Home-Work9-3.png)

![Альт-текст](https://i.ibb.co/pKCVZ0P/Home-Work9-4.png)

### `Создаем тестовые таблицы в каждой ВМ`

**_create table test (i int);_**

**_create table test2 (i int);_**

### `Публикации`

* ВМ-1

**_create publication test_pub_1 for table test;_**

Проверка **_\dRp_**

* ВМ-2

**_create publication test_pub_2 for table test2;_**

Проверка **_\dRp_**

### `Подписка`

* ВМ-1 на ВМ-2

**_create subscription test_sub_2 connection 'host=51.250.102.202 port=5432 user=postgres password=12345 dbname=postgres' publication test_pub_2 with (copy_data = false);_**

Проверка **_\dRs_**

* ВМ-2 на ВМ-1

**_create subscription test_sub_1 connection 'host=84.252.141.141 port=5432 user=postgres password=12345 dbname=postgres' publication test_pub_1 with (copy_data = false);_**

Проверка **_\dRs_**

* ВМ-3 на ВМ-1 и ВМ-2

**_create subscription test_sub_1_3 connection 'host=84.252.141.141 port=5432 user=postgres password=12345 dbname=postgres' publication test_pub_1 with (copy_data = false);_**

**_create subscription test_sub_2_3 connection 'host=51.250.102.202 port=5432 user=postgres password=12345 dbname=postgres' publication test_pub_2 with (copy_data = false);_**

Проверка **_\dRs_**

### `Проверка работы репликации`

* Вставка в test на ВМ-1

**_insert into test (i) values (1), (2), (3), (4), (5);_**

* Проверка на ВМ-2

**_select * from test;_**

* Вставка в test2 на ВМ-2

**_insert into test2 (i) values (10), (20), (30), (40), (50);_**

* Проверка на ВМ-1

**_select * from test2;_**

* Проверка на ВМ-3

**_select * from test;_**

**_select * from test2;_**

![Альт-текст](https://i.ibb.co/spT5rMQ/Home-Work9-5.png)

![Альт-текст](https://i.ibb.co/nBRpGyx/Home-Work9-6.png)

![Альт-текст](https://i.ibb.co/gT8xtcs/Home-Work9-7.png)

### `Описание реализации`

Реализованная репликация упрощенно показывает возможность организации работы, например, трех департаментов организации.
Два департамента изменяют каждый свои таблицы, а таблицы другого департамента получают через репликацию.
Третий департамент - отчетный, его база полностью формируется за счет репликации и используется только для запросов.
Запрет изменения "чужих" таблиц можно реализовать, например, на уровне прав.