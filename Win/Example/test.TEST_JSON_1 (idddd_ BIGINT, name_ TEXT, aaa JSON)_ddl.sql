-- ������ ��� ������� test.TEST_JSON_1 (idddd_ BIGINT, name_ TEXT, aaa JSON) (Interin SQL Studio)
-- ������ 04.12.2024 16:53:43 �� �� interin@postgres

-- ������� test."TEST_JSON_1 (idddd_ BIGINT, name_ TEXT, aaa JSON)"
CREATE OR REPLACE FUNCTION test.test_json_1(idddd_ bigint, name_ text, aaa json)
 RETURNS character varying
 LANGUAGE pl_cpl_sql
AS $function$
declare
    obj json := '{"main_obj": {"1": 123, "2": 456}}';
    new_obj json;
    arr json := '[]';
begin
    dbms_output.put_line('1. obj = '||obj);
    -- ������� ��� ���� ����-��������
    obj := json_io.add(obj, 'id', '1000', 'name', name_);
    dbms_output.put_line('2. obj = '||obj);
    --������� ����� ���������
    new_obj := '{"dddd": 890}';
    obj := json_io.add(obj, 'new_obj', new_obj);
    dbms_output.put_line('3. obj = '||obj);
    ------------
    
    --� ������ arr ������� ����� �������
    arr := json_io.add(arr, '', new_obj);
    dbms_output.put_line('4. arr = '||arr);
    ------------
    --� ������ arr ������� ����� �������
    arr := json_io.add(arr, '', '{"aaaa": 111}');
    dbms_output.put_line('5. arr = '||arr);
    --������� ������ � ������ - obj
    obj := json_io.add(obj, 'rows', arr);
    obj := json_io.add(obj, 'input_obj', aaa);
    dbms_output.put_line('aaa.QQQ = '||aaa.QQQ);
    dbms_output.put_line('5. ���������: obj = '||json_io.format(obj));
    
    return obj;
END;
$function$

/

-- ������ �����������
