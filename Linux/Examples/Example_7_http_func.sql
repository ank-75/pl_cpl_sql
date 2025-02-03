CREATE OR REPLACE FUNCTION test.test_func_https(url_ character varying)
 RETURNS text
 LANGUAGE pl_cpl_sql
AS $function$
--
-- История изменений
-- Персона               Дата          Комментарий
-- -------------------   ------------  ------------------------------------------
-- Azerty      29.11.2024
declare
    http_req http_io.req;
    http_resp http_io.resp;
    res       varchar2;
begin
    --http_req := http_io.begin_request('https://www.wildberries.ru/brands/adidas?sort=popular&page=1&fsupplier=-100', 'GET');
    http_req := http_io.begin_request(url_, 'GET');
    http_io.set_header(http_req, 'Content-Type', 'text/html');
    http_io.set_resp_encoding(http_req, 'UTF8');
    http_resp := http_io.get_response(http_req);
    dbms_output.put_line('HTTP response status code: ' || http_resp.status_code);
    dbms_output.put_line('HTTP response text length: ' || length(http_resp.response_text));
   
    res := http_resp.response_text;
    dbms_output.put_line('HTTP response text: ' || res);
    return res;
end;
$function$
;
