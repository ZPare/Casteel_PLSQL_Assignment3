--Case 7-1 Order Checkout Package

CREATE OR REPLACE PACKAGE shop_process_pkg
IS
  PROCEDURE BASK_CALC_PP
  (pp_idbasket in number,
   pp_subtotal out number,
   pp_tax out number,
   pp_shipping out number,
   pp_total_amt out number);
   
   FUNCTION BB_CAL_TAX_SF
  (pp_idbasket in number,
   pp_subtotal in number)
   RETURN NUMBER;
  
   FUNCTION BB_CAL_SUBTOT_SF
  (pp_idbasket in number)
  RETURN NUMBER;

  FUNCTION BB_CAL_SHIPCOST_SF
  (pp_idbasket in number)
  RETURN NUMBER;

END;

CREATE OR REPLACE
PACKAGE BODY shop_process_pkg AS

--BASK_CALC_PP
   PROCEDURE BASK_CALC_PP
  (pp_idbasket in number,
   pp_subtotal out number,
   pp_tax out number,
   pp_shipping out number,
   pp_total_amt out number) AS

  BEGIN
    pp_subtotal := BB_CAL_SUBTOT_SF(pp_idbasket);
    pp_tax := BB_CAL_TAX_SF(pp_idbasket, pp_subtotal);
    pp_shipping := BB_CAL_SHIPCOST_SF(pp_idbasket);
    pp_total_amt := pp_subtotal + pp_tax + pp_shipping ;
  END BASK_CALC_PP;
  
--BB_CAL_TAX_SF
   FUNCTION BB_CAL_TAX_SF
  (pp_idbasket in number,
   pp_subtotal in number)
  RETURN NUMBER AS
    lv_shipstate bb_basket.shipstate%TYPE;  
    lv_taxrate bb_tax.taxrate%TYPE;
    lv_calc_tax number;

  BEGIN
    SELECT SHIPSTATE
    INTO lv_shipstate 
    FROM BB_BASKET
    WHERE IDBASKET = pp_idbasket;

    SELECT NVL (MAX(TAXRATE), 0)
    INTO lv_taxrate
    FROM BB_TAX
    WHERE STATE = lv_shipstate;
    
    lv_calc_tax := round((pp_subtotal*lv_taxrate), 2);
    RETURN lv_calc_tax; 
  END BB_CAL_TAX_SF;
    
--BB_CAL_SUBTOT_SF
  FUNCTION BB_CAL_SUBTOT_SF
  (pp_idbasket in number)
  RETURN NUMBER AS
    lv_subtot bb_basket.subtotal%TYPE;

  BEGIN
    SELECT SUM(PRICE * QUANTITY)
    INTO lv_subtot
    FROM BB_BASKETITEM
    WHERE IDBASKET = pp_idbasket
    GROUP BY IDBASKET;
    RETURN lv_subtot;
  END BB_CAL_SUBTOT_SF;
  
--BB_CAL_SHIPCOST_SF
  FUNCTION BB_CAL_SHIPCOST_SF
  (pp_idbasket in number)
  RETURN NUMBER AS
    lv_tot_qty bb_basket.quantity%TYPE;
    lv_ship_cost bb_basket.shipping%TYPE;

  BEGIN
    SELECT SUM(QUANTITY)
    INTO lv_tot_qty
    FROM BB_BASKETITEM
    WHERE IDBASKET = pp_idbasket
    GROUP BY IDBASKET;
    
    IF lv_tot_qty > 10 THEN
      lv_ship_cost := 11;
    ELSIF lv_tot_qty > 5 THEN
      lv_ship_cost := 8;
    ELSE
      lv_ship_cost := 5;
    END IF;
    
    RETURN lv_ship_cost; 
  END BB_CAL_SHIPCOST_SF;
  
--end of package
END shop_process_pkg;



--Displaying

SET SERVEROUTPUT ON

DECLARE 
  lv_idbasket number := 3;
--lv_idbasket number := 4;  
  lv_subtotal number;
  lv_shipping number;
  lv_tax number;
  lv_total_amt number;
BEGIN
  shop_process_pkg.BASK_CALC_PP(lv_idbasket, lv_subtotal, lv_shipping, lv_tax, lv_total_amt );
  DBMS_OUTPUT.PUT_LINE('basket ID: '||lv_idbasket);
  DBMS_OUTPUT.PUT_LINE('subtotal amount: '||lv_subtotal);
  DBMS_OUTPUT.PUT_LINE('shipping cost: '||lv_shipping);
  DBMS_OUTPUT.PUT_LINE('tax: '||lv_tax);
  DBMS_OUTPUT.PUT_LINE('total amount: '||lv_total_amt);
END;
