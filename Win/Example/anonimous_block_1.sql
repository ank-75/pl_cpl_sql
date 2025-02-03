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
  f_name varchar2; 
  num_val varchar2;
  i       integer;
begin 
  -- Открытие курсоров в разных соединениях и отдельный запуск функций в них 
  -- 
  dbms_output.put_line('--Start--PG'); 
  -- 
  i := 0;
  for rec in cur_main_pg loop 
      i := i + 1; 
      dbms_output.put_line(i||'. name='||rec.name||', firm_name='||rec.firm_name);
  end loop; 
end;
$$; 
