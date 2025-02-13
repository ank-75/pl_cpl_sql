-------------------------------------------------------------------------------
--Демонстрация возможностей оператора - execute.-------------------------------
-------------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare
    sql_stmt    VARCHAR2;
  
    cursor cur_main_pg is 
		select * 
		    from /*##db=db_NewConn##*/ 
		        test.categories ct 
	    	order by ct.description;  
begin 
  dbms_output.put_line('--Create table');

  -- Копируем параметры соединения - db_PG в параметры - db_NewConn
  -- Для того, чтобы в рамках одного кода можно было бы открывать несколько соединений к одной БД
  copy_connection_params('db_PG', 'db_NewConn'); 
  --Либо можем сразу определить новое соединение с новыми параметрами
  --create_connection_params('db_NewConn', 'PSQL', 'username', 'password', 'host', 'db_name', 'port', 'true');  
 
  --Создадим тестовую таблицу 
  EXECUTE /*##db=db_NewConn##*/ 'CREATE TABLE if not exists test.categories (
    category_id smallint NOT NULL,
    category_name character varying(15) NOT NULL,
    description text
);';
  
  dbms_output.put_line('--Clear table');
 
  -- Очистим таблицу с категориями
  delete /*##db=db_NewConn##*/ from test.categories;

  dbms_output.put_line('--Insert'); 
 
  --Заполним таблицу данными 
  sql_stmt := '
do
$block$
begin
	INSERT INTO test.categories VALUES (1, ''Beverages'', ''Soft drinks, coffees, teas, beers, and ales'');
	INSERT INTO test.categories VALUES (2, ''Condiments'', ''Sweet and savory sauces, relishes, spreads, and seasonings'');
	INSERT INTO test.categories VALUES (3, ''Confections'', ''Desserts, candies, and sweet breads'');
	INSERT INTO test.categories VALUES (4, ''Dairy Products'', ''Cheeses'');
	INSERT INTO test.categories VALUES (5, ''Grains/Cereals'', ''Breads, crackers, pasta, and cereal'');
	INSERT INTO test.categories VALUES (6, ''Meat/Poultry'', ''Prepared meats'');
	INSERT INTO test.categories VALUES (7, ''Produce'', ''Dried fruit and bean curd'');
	INSERT INTO test.categories VALUES (8, ''Seafood'', ''Seaweed and fish'');
end;
$block$';
 
  	--выполним анонимный блок
  EXECUTE /*##db=db_NewConn##*/ sql_stmt;
  
  dbms_output.put_line('--Select data');
 
  --Выведем на экран содержимое созданной таблицы
  for rec in cur_main_pg loop
   	dbms_output.put_line(json_io.record_to_json(rec));
  end loop; 
 
end;
$$; 
