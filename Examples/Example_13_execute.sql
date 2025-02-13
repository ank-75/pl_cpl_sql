-------------------------------------------------------------------------------
--Демонстрация возможностей оператора - execute. Соединение с различными БД----
-------------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare
  patt      varchar2 := '%';

  -- 
  cursor cur_main_ora is 
      select A.*
       from /*##db=db_Oracle##*/ 
            apt.table_name a
      where lower(a.name) like '%'||patt||'%';        
  -- 
  f_name    varchar2; 
  num_val   varchar2;
  i         integer;
begin 
  dbms_output.put_line('--Start-- Oracle'); 
  -- 
  
  -- Создаем таблицу в БД - db_PG 
  execute /*##db=db_PG##*/ 'CREATE TABLE if not exists test.table_name_dub (
    "id"                              BIGINT NOT NULL,
    "code"                            VARCHAR(30) ,
    "name"                            VARCHAR(2000)  NOT NULL,
    "intername"                       VARCHAR(300) ,
    "form_name"                       VARCHAR(300) ,
    "firm_name"                       VARCHAR(255) ,
    "country_name"                    VARCHAR(255) ,
    "pharm_gr"                        VARCHAR(300) ,
    "medic_type"                      BIGINT,
    "kls_id"                          BIGINT,
    "status"                          NUMERIC(2,0),
    "measure_id"                      BIGINT,
    "quantity"                        NUMERIC,
    "in_date"                         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "operator_id"                     BIGINT NOT NULL,
    "store_gr_id"                     BIGINT,
    "store_cond"                      VARCHAR(2000) ,
    "vital"                           VARCHAR(50) ,
    "stock_gr_id"                     BIGINT,
    "toxic_id"                        BIGINT,
    "small_measure_id"                BIGINT,
    "factor"                          NUMERIC(12,2),
    "firm_id"                         BIGINT,
    "pharm_gr_id"                     BIGINT,
    "country_id"                      BIGINT,
    "inter_name_id"                   BIGINT,
    "latin_name"                      VARCHAR(255) ,
    "payment_id"                      BIGINT,
    "ttt_name"                        VARCHAR(255) ,
    "neu_chk"                         NUMERIC(1,0),
    "neu"                             NUMERIC,
    "method_use"                      VARCHAR(2000) ,
    "expire_time"                     BIGINT,
    "method_use_id"                   BIGINT,
    "latin_form_name"                 VARCHAR(255) ,
    "measure_id_doctor"               BIGINT,
    "form_name_doctor"                VARCHAR(300) ,
    "lat_meas_id_doctor"              BIGINT,
    "lat_form_name_doctor"            VARCHAR(300) ,
    "name_doctor"                     VARCHAR(2000) ,
    "lat_name_doctor"                 VARCHAR(255) ,
    "object_stock"                    VARCHAR(10) ,
    "barcode_orig"                    VARCHAR(255) ,
    "social"                          NUMERIC,
    "mult"                            NUMERIC,
    "barcode_1"                       VARCHAR(255) ,
    "barcode_2"                       VARCHAR(255) ,
    "barcode_3"                       VARCHAR(255) ,
    "cell_flag"                       NUMERIC(10,2),
    "course_flag"                     NUMERIC(2,0),
    "meas_qt_sm_id"                   BIGINT,
    "qt_doctor"                       NUMERIC,
    "qt_small_meas"                   NUMERIC,
    "small_quantity"                  NUMERIC,
    "okp_code"                        BIGINT,
    "indivis"                         NUMERIC(1,0),
    "price_tarif"                     NUMERIC,
    "price_vs_mat"                    NUMERIC,
    "mult_measure_id"                 NUMERIC,
    "akciz"                           NUMERIC(10,2),
    "dict_type"                       VARCHAR(255) ,
    "nds"                             NUMERIC,
    "last_upd_date"                   TIMESTAMP WITHOUT TIME ZONE,
    "last_upd_fio"                    VARCHAR(255) ,
    "parus_nom_id"                    BIGINT,
    "rls_id_rls_nomen"                BIGINT,
    "rls_tradename"                   VARCHAR(1024) ,
    "rls_mnn_litin"                   VARCHAR(1027) ,
    "rls_drugforms"                   VARCHAR(1024) ,
    "rls_conc"                        NUMERIC(14,4),
    "rls_ed_conc"                     VARCHAR(1024) ,
    "rls_min_pac"                     VARCHAR(1024) ,
    "rls_m_min_pac"                   NUMERIC(14,6),
    "rls_ed_m_min_pac"                VARCHAR(1024) ,
    "rls_v_min_pac"                   NUMERIC(14,4),
    "rls_ed_v_min_pac"                VARCHAR(1024) ,
    "rls_kol_vi_min_upcak"            BIGINT,
    "rls_pac2_name"                   VARCHAR(1024) ,
    "rls_dfmass"                      VARCHAR(50) ,
    "rls_ed_dfmass"                   VARCHAR(50) ,
    "rls_pac3_name"                   VARCHAR(1024) ,
    "rls_kol_vi_pac2_upcak"           BIGINT,
    "rls_id_rls_prep"                 BIGINT,
    "nomen_id_nomen"                  VARCHAR(255) ,
    "nomen_group"                     VARCHAR(255) ,
    "nomen_kosgu"                     VARCHAR(255) ,
    "dosage"                          VARCHAR(255) ,
    "external_id"                     BIGINT,
    "ext_root_id"                     BIGINT,
    "parent_id"                       BIGINT,
    "code_ath"                        VARCHAR(255) ,
    "ethanol_qty"                     NUMERIC DEFAULT 0,
    "cert"                            VARCHAR(255) ,
    "ndcode"                          VARCHAR(100) ,
    "ndcode_arc"                      VARCHAR(100) ,
    "srch_patt"                       VARCHAR(2000) ,
    "div_apteka"                      VARCHAR(24) ,
    "short_name"                      VARCHAR(500) ,
    "drug_form"                       VARCHAR(255) ,
    "direction_for_use"               VARCHAR(255) ,
    "product_size"                    VARCHAR(30) ,
    "log_field"                       VARCHAR(2000) ,
    "nom_source"                      VARCHAR(10) ,
    "factor_rasf"                     NUMERIC(12,2),
    "atx_code"                        VARCHAR(7) ,
    "gnvlp"                           NUMERIC(1,0)
)
'; 
 
  -- Очищаем таблицу - test.table_name_dub
  execute /*##db=db_PG##*/ 'delete from test.table_name_dub';

  dbms_output.put_line('patt = '||patt);
  i := 0; 
  -- Выполняем запрос в БД - db_Oracle
  for rec in cur_main_ora loop 
      -- Выполним функцию в БД и вернем ее результат 
      f_name := test.func_name/*##db=db_Oracle##*/(rec.id); 
      -- 
      i := i + 1; 
      dbms_output.put_line(i||') Name = '||f_name||', meas_name='||test.func_measure_name/*##db=db_Oracle##*/(rec.measure_id));
      --record_io.print_record(rec);
	  
	  -- Вставим данные в таблицу test.table_name_dub в БД - db_PG
      insert into /*##db=db_PG##*/ test.table_name_dub values(rec.*); 
  end loop;
  
end;
$$; 
