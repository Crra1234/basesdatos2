CREATE DIRECTORY image_files 
AS 
  'C:\Users\Crra\OneDrive\Documents\GitHub\basesdatos2\IMG'; 
  DECLARE 
    l_blob BLOB; 
    v_src_loc BFILE := BFILENAME('IMAGE_FILES', 'venezuela.jpg'); 
    v_amount INTEGER; 
  BEGIN 
    UPDATE PAIS 
        SET Bandera = EMPTY_BLOB()
    RETURN BANDERA 
    INTO l_blob; 
    DBMS_LOB.OPEN(v_src_loc, DBMS_LOB.LOB_READONLY); 
    v_amount := DBMS_LOB.GETLENGTH(v_src_loc); 
    DBMS_LOB.LOADFROMFILE(l_blob, v_src_loc, v_amount); 
    DBMS_LOB.CLOSE(v_src_loc); 
    COMMIT; 
  END;