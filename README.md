# Здесь представлен интерпретатор языка программирования (похожего на Oracle PL/SQL), который реализован в виде расширения для БД PostgreSQL. 
В БД этот язык будет называться - <b>pl_cpl_sql</b>. 
Сам интерпретатор собран в виде динамичесой библиотеки (<b>/Linux/Lib/libpl_cpl_sql_lib.so</b> для <b>Linux</b>, <b>/Win/Lib/pl_cpl_sql_lib.dll</b> для <b>Windows</b>). 

<h3>Установка, если БД PostgreSQL расположена на компьютере с OS Linux:</h3>
(дополнительно должен быть установле пакет - <b>postgresql-devel</b>)

1) В отдельный каталог копируем файлы (/Linux/):<br>
	<b>makefile<br>
	pl_cpl_sql_ext--1.0.sql<br>
	pl_cpl_sql_ext.c<br>
	pl_cpl_sql_ext.control</b>
	
2) Выполняем команды:<br>
    <b>make<br>
	make install</b>
	
3) С помощью <b>pgAdmin</b> или <b>DBeaver</b> выполняем sql-файл - <b>/Linux/pl_cpl_sql_ext--1.0.sql</b>.<br>

4) Из каталога <b>/Linux/Lib</b> файлы копируем в каталог <b>/usr/lib64.</b><br> 
   (Либо в другой какой-то каталог, который потом надо добавить в переменную - <b>LD_LIBRARY_PATH</b>).<br>
   В файле <b>conn_params.json</b> указываем параметры соединения с текущей БД <b>PostgreSQL</b>.<br> 
   Если будем работать с <b>Oracle</b> - указываем и параметры для соединения с БД <b>Oracle</b>.<br>
   Для <b>Oracle</b> нужно будет установить пакет из каталога <b>/Linux/OracleClient</b>.
   
<h3>Установка, если БД PostgreSQL расположена на компьютере с OS Windows:</h3>

1) Для того, чтобы на основе файла <b>/Win/pl_cpl_sql_ext.c</b> собрать библиотеку <b>pl_cpl_sql_ext.dll</b> можно воспользоваться ссылкой - https://www.highgo.ca/2020/05/15/build-postgresql-and-extension-on-windows/.<br>
   Там указано, как с помощью <b>Visual Studio</b> собрать такую библиотеку.<br>
   
   Так же в каталогах <b>/Win/LibPG/15/</b> и <b>/Win/LibPG/16/</b> имеются версии данной библиотеки, собранные для <b>PostgreSQL</b> 15 или 16 версии.<br>
   
   Собранную библиотеку копируем в каталог - <b>...\PostgreSQL\<версия>\lib</b>.<br>
   
2) Копируем файлы из каталога <b>/Win/Lib/</b> в отдельный каталог и добавляем к нему путь в переменную - <b>PATH</b>.<br>

   В файле <b>conn_params.json</b> указываем параметры соединения с текущей БД <b>PostgreSQL</b>.<br> 
   Если будем работать с <b>Oracle</b> - указываем и параметры для соединения с БД <b>Oracle</b>.<br>
   Для <b>Oracle</b> нужно будет установить <b>OracleClient</b>.<br>

3) С помощью <b>pgAdmin</b> или <b>DBeaver</b> выполняем sql-файл - <b>/Win/pl_cpl_sql_ext--1.0.sql.</b><br>     

Далее, если установка прошла успешно, можно попробовать выполнить примеры из каталога <b>/Examples/</b>.
