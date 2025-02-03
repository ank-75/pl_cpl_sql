do
LANGUAGE pl_cpl_sql
$$
declare
  -- 
  cursor cur_main_pg is 
      select * 
       from /*##db=db_PG##*/ 
            apt.n_medic_regs a
      where lower(a.name) like '%парацет%';
      
  -- 
  cursor cur_main_ora is 
      select * 
       from /*##db=db_Oracle##*/ 
            apt.n_medic_regs a
      where lower(a.name) like '%парацет%';        
  -- 
  f_name varchar2; 
  num_val varchar2;
  i       integer;
begin 
  /*
  -- Открытие курсоров в разных соединениях и отдельный запуск функций в них 
  -- 
  dbms_output.put_line('--Start--PG'); 
  -- 
  i := 0;
  for rec in cur_main_pg loop 
      i := i + 1; 
      dbms_output.put_line(i||'. name='||rec.name||', firm_name='||rec.firm_name);
  end loop;
  */ 
  
  -- 
  dbms_output.put_line(' '); 
  dbms_output.put_line('--Start--Oracle'); 
  -- 
  for rec in cur_main_ora loop 
      -- Выполним функцию в БД и вернем ее результат 
      f_name := apt.n_get_reg_name/*##db=db_Oracle##*/(rec.registry_id); 
      -- 
      dbms_output.put_line('Name = '||f_name||', meas_name='||apt.n_get_measure_name/*##db=db_ORACLE##*/(rec.input_measure_id)); 
  end loop;  
end;
$$; 
