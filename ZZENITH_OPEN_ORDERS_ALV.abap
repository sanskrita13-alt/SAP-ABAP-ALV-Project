*&---------------------------------------------------------------------*
*& Report  ZZENITH_OPEN_ORDERS_ALV
*& Custom ALV Report — Customer-Wise Open Sales Orders
*& Author  : [Your Name] | Roll No: [Your Roll No] | Batch: [Your Batch]
*& Company : Zenith Retail Pvt. Ltd. (Fictitious Scenario)
*& Package : ZREPORTS | Transaction: SE38
*&---------------------------------------------------------------------*

REPORT zzenith_open_orders_alv LINE-SIZE 255 NO STANDARD PAGE HEADING.

*----------------------------------------------------------------------*
* STEP 2 — Global Data & Type Structures
*----------------------------------------------------------------------*

TYPES: BEGIN OF ty_orders,
         vbeln   TYPE vbak-vbeln,      " Sales Order Number
         erdat   TYPE vbak-erdat,      " Order Creation Date
         auart   TYPE vbak-auart,      " Order Type
         kunnr   TYPE kna1-kunnr,      " Customer Number
         name1   TYPE kna1-name1,      " Customer Name
         ort01   TYPE kna1-ort01,      " Customer City
         posnr   TYPE vbap-posnr,      " Item Position Number
         matnr   TYPE vbap-matnr,      " Material Number
         arktx   TYPE vbap-arktx,      " Item Description
         kwmeng  TYPE vbap-kwmeng,     " Ordered Quantity
         netwr   TYPE vbap-netwr,      " Net Value (Item Level)
         waerk   TYPE vbak-waerk,      " Currency Key
         lfsta   TYPE vbup-lfsta,      " Delivery Status
         color   TYPE c LENGTH 4,      " ALV Row Color Key
       END OF ty_orders.

DATA: it_orders   TYPE STANDARD TABLE OF ty_orders,
      wa_orders   TYPE ty_orders,
      it_fcat     TYPE lvc_t_fcat,
      wa_fcat     TYPE lvc_s_fcat,
      gs_layout   TYPE lvc_s_layo,
      go_alv      TYPE REF TO cl_gui_alv_grid,
      go_container TYPE REF TO cl_gui_custom_container.

*----------------------------------------------------------------------*
* STEP 3 — Selection Screen
*----------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: so_erdat FOR sy-datum OBLIGATORY,   " Order Date Range
                  so_kunnr FOR kna1-kunnr,             " Customer Number Range
                  so_auart FOR vbak-auart.             " Order Type Range
  PARAMETERS:     p_lfsta  TYPE vbup-lfsta DEFAULT 'A'. " Delivery Status Filter
SELECTION-SCREEN END OF BLOCK blk1.

*----------------------------------------------------------------------*
* STEP 4 — Fetch Data Using Optimized Inner Join
*----------------------------------------------------------------------*

START-OF-SELECTION.

  SELECT a~vbeln a~erdat a~auart a~waerk
         c~kunnr c~name1 c~ort01
         b~posnr b~matnr b~arktx b~kwmeng b~netwr
         d~lfsta
    INTO CORRESPONDING FIELDS OF TABLE it_orders
    FROM vbak AS a
    INNER JOIN vbap AS b ON b~vbeln  = a~vbeln
    INNER JOIN kna1 AS c ON c~kunnr  = a~kunnr
    INNER JOIN vbup AS d ON d~vbeln  = b~vbeln
                        AND d~posnr  = b~posnr
   WHERE a~erdat  IN so_erdat
     AND a~kunnr  IN so_kunnr
     AND a~auart  IN so_auart
     AND d~lfsta  <> 'C'.           " Exclude fully delivered orders

  IF it_orders IS INITIAL.
    MESSAGE 'No open sales orders found for the selected criteria.' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

*----------------------------------------------------------------------*
* STEP 5 — Apply Color Coding Based on Order Age
*----------------------------------------------------------------------*

  LOOP AT it_orders INTO wa_orders.

    DATA(lv_age) = sy-datum - wa_orders-erdat.  " Days since order was created

    IF lv_age > 30.
      wa_orders-color = 'C610'.    " Red    — Overdue, needs immediate action
    ELSEIF lv_age BETWEEN 15 AND 30.
      wa_orders-color = 'C510'.    " Yellow — Approaching risk threshold
    ELSE.
      wa_orders-color = 'C310'.    " Green  — Within acceptable fulfillment window
    ENDIF.

    MODIFY it_orders FROM wa_orders.

  ENDLOOP.

*----------------------------------------------------------------------*
* STEP 6 — Build Field Catalog Dynamically
*----------------------------------------------------------------------*

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = sy-repid
      i_internal_tabname = 'IT_ORDERS'
      i_inclname         = sy-repid
    CHANGING
      ct_fieldcat        = it_fcat.

  " Customize individual field properties
  LOOP AT it_fcat INTO wa_fcat.
    CASE wa_fcat-fieldname.
      WHEN 'VBELN'.
        wa_fcat-key      = 'X'.
        wa_fcat-coltext  = 'Sales Order'.
        wa_fcat-outputlen = 12.
      WHEN 'ERDAT'.
        wa_fcat-coltext  = 'Order Date'.
      WHEN 'KUNNR'.
        wa_fcat-coltext  = 'Customer No.'.
      WHEN 'NAME1'.
        wa_fcat-coltext  = 'Customer Name'.
        wa_fcat-outputlen = 30.
      WHEN 'ORT01'.
        wa_fcat-coltext  = 'City'.
      WHEN 'MATNR'.
        wa_fcat-coltext  = 'Material No.'.
      WHEN 'ARKTX'.
        wa_fcat-coltext  = 'Description'.
        wa_fcat-outputlen = 30.
      WHEN 'KWMENG'.
        wa_fcat-coltext  = 'Quantity'.
        wa_fcat-do_sum   = 'X'.       " Show subtotal for quantity
      WHEN 'NETWR'.
        wa_fcat-coltext  = 'Net Value'.
        wa_fcat-do_sum   = 'X'.       " Show subtotal for net value
      WHEN 'LFSTA'.
        wa_fcat-coltext  = 'Delivery Status'.
      WHEN 'COLOR'.
        wa_fcat-no_out   = 'X'.       " Hide color column — used internally only
    ENDCASE.
    MODIFY it_fcat FROM wa_fcat.
  ENDLOOP.

*----------------------------------------------------------------------*
* STEP 7 — Configure ALV Layout and Display Grid
*----------------------------------------------------------------------*

  gs_layout-zebra      = 'X'.       " Alternating row shading for readability
  gs_layout-cwidth_opt = 'X'.       " Auto-fit all column widths
  gs_layout-info_fname = 'COLOR'.   " Apply row color from COLOR field
  gs_layout-grid_title = 'Zenith Retail — Open Sales Orders Dashboard'.

  " Create container and ALV grid object
  CREATE OBJECT go_container
    EXPORTING container_name = 'MAIN_CONTAINER'.

  CREATE OBJECT go_alv
    EXPORTING i_parent = go_container.

  " Display the ALV grid with data, layout and field catalog
  go_alv->set_table_for_first_display(
    EXPORTING
      is_layout       = gs_layout
    CHANGING
      it_outtab       = it_orders
      it_fieldcatalog = it_fcat ).
