CREATE OR REPLACE FUNCTION test.test_json(p_int bigint, p_name text, p_json json)
 RETURNS character varying
 LANGUAGE pl_cpl_sql
AS $function$
declare
    obj json := '{"main_obj": {"1": 123, "2": 456}}';
    new_obj json;
    arr json := '[]';
begin
    dbms_output.put_line('1. obj = '||obj);
    -- Добавим две пары ключ-значение
    obj := json_io.add(obj, 'id', '1000', 'name', p_name);
    dbms_output.put_line('2. obj = '||obj);
    --Добавим новый подобъект
    ---
    new_obj := '{"dddd": 890}';
    obj := json_io.add(obj, 'new_obj', new_obj);
    dbms_output.put_line('3. obj = '||obj);
    ------------

    --name_ := '123123123';

    --В массив arr добавим новый элемент
    arr := json_io.add(arr, '', new_obj);
    dbms_output.put_line('4. arr = '||arr);
    ------------
    --В массив arr добавим новый элемент
    arr := json_io.add(arr, '', '{"aaaa": 111}');
    dbms_output.put_line('5. arr = '||arr);
    --Добавим массив в объект - obj
    obj := json_io.add(obj, 'rows', arr);
    obj := json_io.add(obj, 'input_obj', p_json);
    dbms_output.put_line('aaa.QQQ = '||p_json.QQQ);
    dbms_output.put_line('5. Результат: obj = '||json_io.format(obj));

    return obj;
END;
$function$
;
