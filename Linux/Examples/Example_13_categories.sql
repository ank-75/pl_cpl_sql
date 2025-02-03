do
LANGUAGE pl_cpl_sql
$$
declare
    sql_stmt    VARCHAR2;
  
    cursor cur_main_pg is 
		select * 
		    from /*##db=db_PG##*/ 
		        test.categories ct 
	    	order by ct.description;  
begin 
  dbms_output.put_line('--Create table');

  --Создадим тестовую таблицу 
  EXECUTE /*##db=db_PG##*/ 'CREATE TABLE if not exists test.categories (
    category_id smallint NOT NULL,
    category_name character varying(15) NOT NULL,
    description text
);';
  
  dbms_output.put_line('--Clear table');
 
  -- Очистим таблицу с категориями
  delete /*##db=db_PG##*/ from test.categories;

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
  EXECUTE /*##db=db_PG##*/ sql_stmt;
  
  dbms_output.put_line('--Select data');
 
  --Выведем на экран содержимое созданной таблицы
  for rec in cur_main_pg loop
   	dbms_output.put_line(json_io.record_to_json(rec));
  end loop; 
 
end;
$$; 
