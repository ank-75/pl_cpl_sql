# Здесь представлен интерпретатор языка программирования (похожего на Oracle PL/SQL), который реализован в виде расширения для БД PostgreSQL. 
В БД этот язык будет называться - pl_cpl_sql.

Установка, если БД PostgreSQL расположена на компьютере с OS Linux:
(дополнительно должен быть установле пакет - postgresql-devel)

1) В отдельный каталог копируем файлы (/Linux/):
	makefile
	pl_cpl_sql_ext--1.0.sql
	pl_cpl_sql_ext.c
	pl_cpl_sql_ext.control
	
2) Выполняем команды:
    make
	make install
	
3) С помощью pgAdmin или DBeaver выполняем sql-файл - /Linux/pl_cpl_sql_ext--1.0.sql.

4) Из каталога /Linux/Lib файлы копируем в каталог /usr/lib64. 
   (Либо в другой какой-то каталог, который потом надо добавить в переменную - LD_LIBRARY_PATH).
   В файле conn_params.json указываем параметры соединения с текущей БД PostgreSQL. 
   Если будем работать с Oracle - указываем и параметры для соединения с БД Oracle.
   Для Oracle нужно будет установить пакет из каталога /Linux/OracleClient.
   
   
Установка, если БД PostgreSQL расположена на компьютере с OS Windows:

1) Для того, чтобы на основе файла /Win/pl_cpl_sql_ext.c собрать библиотеку pl_cpl_sql_ext.dll можно воспользоваться ссылкой.
   Там указано, как с помощью Visual Studio собрать такую библиотеку.
   
   Так же в каталогах /Win/LibPG/15/ и /Win/LibPG/16/ имеются версии данной библиотеки, собранные для PostgreSQL 15 или 16 версии.
   
   Собранную библиотеку копируем в каталог - ...\PostgreSQL\<версия>\lib.
   
2) Копируем файлы из каталога /Win/Lib/ в отдельный каталог и добавляем к нему путь в переменную - PATH.

   В файле conn_params.json указываем параметры соединения с текущей БД PostgreSQL. 
   Если будем работать с Oracle - указываем и параметры для соединения с БД Oracle.
   Для Oracle нужно будет установить OracleClient.

3) С помощью pgAdmin или DBeaver выполняем sql-файл - /Win/pl_cpl_sql_ext--1.0.sql.     

Далее, если установка прошла успешно, можно попробовать выполнить примеры из каталога /Examples/.
