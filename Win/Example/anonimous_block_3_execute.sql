do
LANGUAGE pl_cpl_sql
$$
declare
   sql_stmt    VARCHAR2(200);
   plsql_block VARCHAR2(500);
   emp_id      NUMBER(4) := 60;
   salary      NUMBER(7,2);
   dept_id     NUMBER(2) := 50;
   dept_name   VARCHAR2(14) := 'PERSONNEL';
   location    VARCHAR2(13) := 'DALLAS';
   emp_rec     record;
   obj         json;
   res_str     varchar2;
begin 
  --EXECUTE IMMEDIATE c SQL предложением
  EXECUTE /*##db=db_PG##*/ 'CREATE TABLE if not exists test.dept (dept_id bigint not null, dept_name text, location text)';
  
  dbms_output.put_line('--111'); 
 
  --присвоим sql_stmt строковое SQL предложение с заполнителями :1, :2, :3
  sql_stmt := 'INSERT INTO test.dept VALUES (:1, :2, :3)';
 
  --запустим EXECUTE IMMEDIATE с sql_stmt используя аргументы связывания dept_id, dept_name, location
  EXECUTE /*##db=db_PG##*/ sql_stmt USING dept_id, dept_name, location;
  dbms_output.put_line('--222');  
  
  --присвоим sql_stmt строковое SQL предложение с заполнителями :1, :2, :3
  sql_stmt := 'INSERT INTO test.dept VALUES (:1, :2, :3)';
 
  --запустим EXECUTE IMMEDIATE с sql_stmt используя аргументы связывания dept_id, dept_name, location
  EXECUTE /*##db=db_PG##*/ sql_stmt USING 60, 'США', 'Америка';
  dbms_output.put_line('--333');  
 
  --присвоим sql_stmt SQL предложение с заполнителем :id
  sql_stmt := 'SELECT * FROM test.dept WHERE dept_id = :id';
 
  --запустим EXECUTE IMMEDIATE с sql_stmt используя аргумент связывания emp_id и сохраним результат в emp_rec
  EXECUTE /*##db=db_PG##*/ sql_stmt INTO emp_rec USING emp_id;
  
  record_io.print_record(emp_rec); 
  
  dept_name := 'США';
  dept_name := '{"ID": "'||dept_name||'"}';
  dbms_output.put_line('dept_name='||dept_name); 
  dbms_output.put_line('emp_rec.dept_name='||emp_rec.dept_name);  
 
  execute /*##db=db_PG##*/ 'select test.test_json_2  (:idddd_, :name_, :aaa)' into res_str using 123, 'Тестовый пример', dept_name;
  dbms_output.put_line('res_str='||res_str);    
  
  plsql_block := '
do
LANGUAGE pl_cpl_sql
$aaa$
begin
  dbms_output.put_line(''--Message from block'');
end
$aaa$'; 
  
  execute /*##db=db_PG##*/ plsql_block;  
   
end;
$$; 
