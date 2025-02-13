--------------------------------------------------------------------------------------------------------------------
--Определим функцию в БД, которая демонстрирует работу с json-объектами (с помощью пакета json_io)------------------
--------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION test.test_json(p_int bigint, p_name text, p_json json)
 RETURNS text
 LANGUAGE pl_cpl_sql
AS $function$
declare
    obj json := '{"main_obj": {"1": 123, "2": 456}}';
    new_obj json;
    arr json := '[]';
begin
    dbms_output.put_line('1. obj = '||obj);
    
	------------
	-- Добавим две пары ключ-значение
    obj := json_io.add(obj, 'id', '1000', 'name', p_name);
    dbms_output.put_line('2. obj = '||obj);
	
	------------
    --Добавим новый подобъект
    new_obj := '{"dddd": 890}';
    obj := json_io.add(obj, 'new_obj', new_obj);
    dbms_output.put_line('3. obj = '||obj);
	
    ------------
    --В массив arr добавим новый элемент
    arr := json_io.add(arr, '', new_obj);
    dbms_output.put_line('4. arr = '||arr);
	
    ------------
    --В массив arr добавим новый элемент
    arr := json_io.add(arr, '', '{"aaaa": 111}');
    dbms_output.put_line('5. arr = '||arr);
	
	------------
    --Добавим массив в объект - obj
    obj := json_io.add(obj, 'rows', arr);
    obj := json_io.add(obj, 'input_obj', p_json);
	
	------------
    --Выведем результат на экран 
    dbms_output.put_line('6. Результат: obj = '||json_io.format(obj));

	------------
    --Вернем результат как значение функции
    return obj;
END;
$function$
;
