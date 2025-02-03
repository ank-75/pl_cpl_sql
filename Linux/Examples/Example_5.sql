do
LANGUAGE pl_cpl_sql
$$
declare 
     cursor c is 
        select * 
         from /*##db=db_PG##*/ 
             apt.n_medic_regs nmr 
         where nmr.status = 0
        order by nmr."name"; 
 res varchar2; 
 file1 text_io.file_type; 
 ind integer; 
begin 
 -- Все данные из курсора запишем в файл в виде JSON-массива 
 -- Откроем файл для записи 
 file1 := text_io.fopen('/home/alex/Examples/my_json_file.txt','w','UTF8'); 
 -- Запишем строку в файл 
 text_io.put_line( file1, '['); 
 ind := 0; 
 -- Откроем курсор 
 for rec in c loop 
    ind := ind + 1; 
    -- Преобразуем record в json 
    res := json_io.record_to_json(rec); 
    --Запишем данные в файл 
    if ind = 1 then 
     text_io.put_line(file1, res); 
    else 
     text_io.put_line(file1, ','||chr(10)||res); 
    end if; 
 end loop; 
 -- Запишем строку в файл 
 text_io.put_line(file1, ']'); 
 -- Закроем файл 
 text_io.fclose(file1); 
 dbms_output.put_line('ok'); 
end;     
$$