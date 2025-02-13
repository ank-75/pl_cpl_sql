-----------------------------------------------------------------------------
--Отправка post-запроса и получение ответа (с помощью пакета http_io)--------
-----------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
    http_req http_io.req; 
    http_resp http_io.resp; 
begin 
    http_req := http_io.begin_request('https://httpbin.org/post', 'POST'); 
    http_io.set_header(http_req, 'Content-Type', 'application/json'); 
    http_io.set_resp_encoding(http_req, 'UTF8'); 
    http_io.write_text(http_req, '{"command":"FIND_INCOME_DOC", 
                                 "body":{"filter":{"start_date":"2024-06-26T00:00:00","end_date":"2024-06-26T23:59:59"},"start_from":0,"count":100} 
                                 }');     
    http_resp := http_io.get_response(http_req); 
    dbms_output.put_line('HTTP response status code: ' || http_resp.status_code); 
    dbms_output.put_line('HTTP response text: ' || http_resp.response_text); 
end;    
$$; 