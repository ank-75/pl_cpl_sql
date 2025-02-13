-----------------------------------------------------------------------------
--Вернем данные из запроса, открытого в соединении db_PG---------------------
-----------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
        -- 
    cursor cur_main_pg is 
        select * 
         from /*##db=db_PG##*/ 
             apt.table_name nmr 
         where nmr.status = 0
        order by nmr.name; 
    -- 
    ind  integer; 
begin 
    -- 
    dbms_output.put_line('--Start--'); 
    -- 
    ind := 0;
    for rec in cur_main_pg loop
    	ind := ind + 1;
        dbms_output.put_line(ind||') rec: '||json_io.record_to_json(rec));		
    end loop; 
end; 
$$