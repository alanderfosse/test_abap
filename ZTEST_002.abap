*&---------------------------------------------------------------------*
*& Report ZTEST_002
*&---------------------------------------------------------------------*
REPORT ZTEST_002.


*Global Data Declarations
CLASS lcl_report DEFINITION DEFERRED.
DATA: lo_report TYPE REF TO lcl_report. "Reference object of the local class
DATA: alv_container TYPE REF TO cl_gui_docking_container, "ALV Container
      alv_grid      TYPE REF TO cl_gui_alv_grid,          "ALV Grid
      layout        TYPE lvc_s_layo.                      "Layout Options
DATA gv_carrid TYPE sflight-carrid. "Variable for Select-options declaration.


*Selection Screen Declarations
SELECTION-SCREEN: BEGIN OF BLOCK block_1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_carrid FOR gv_carrid.
SELECTION-SCREEN: END   OF BLOCK block_1.



*Local Class Definition
CLASS lcl_report DEFINITION .

  PUBLIC SECTION.
    DATA: gt_data TYPE STANDARD TABLE OF sflight.
    METHODS :
      get_data,
      generate_output,
      toolbar      FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object, "To add some buttons on the ALV toolbar
      user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

ENDCLASS.



*Local Class Implementation
CLASS lcl_report IMPLEMENTATION.
  "Method Get Data
  METHOD get_data.
*   data selection
    SELECT * FROM sflight
           INTO  TABLE me->gt_data
           WHERE carrid IN s_carrid.
    IF sy-dbcnt IS INITIAL.
      MESSAGE s398(00) WITH 'No data selected'.
    ENDIF.
*
*   Export to memory
    EXPORT data = me->gt_data TO MEMORY ID sy-cprog.
  ENDMETHOD.



  "Method generate_output
  METHOD generate_output.
*   Local data
    DATA: variant TYPE  disvariant.
    DATA: repid   TYPE sy-repid.

*   Import output table from the memory and free afterwards
    IMPORT data = me->gt_data FROM MEMORY ID sy-cprog.
    FREE MEMORY ID sy-cprog.
*

*   Only if there is some data
    CHECK me->gt_data IS NOT INITIAL.

    repid = sy-repid.
    variant-report = sy-repid.
    variant-username = sy-uname.
    layout-zebra = 'X'.

    CHECK alv_container IS INITIAL.
    CREATE OBJECT alv_container
      EXPORTING
        repid     = repid
        dynnr     = sy-dynnr
        side      = alv_container->dock_at_bottom
        extension = 200.
    CREATE OBJECT alv_grid
      EXPORTING
        i_parent = alv_container.
*  ALV Specific. Data selection.
    SET HANDLER : lo_report->toolbar      FOR alv_grid.
    SET HANDLER : lo_report->user_command FOR alv_grid.
    CALL METHOD alv_grid->set_table_for_first_display
      EXPORTING
        is_layout        = layout
        is_variant       = variant
        i_save           = 'U'
        i_structure_name = 'SFLIGHT'
      CHANGING
        it_outtab        = me->gt_data.

  ENDMETHOD.




  "Method Tool-bar
  METHOD toolbar.
    DATA: lv_toolbar TYPE stb_button.

* Push Button "For Example SAVE
    CLEAR lv_toolbar.
    MOVE 'FC_SAVE' TO lv_toolbar-function. "Function Code
    lv_toolbar-icon = icon_system_save.    "Save Icon
    MOVE 'Save'(100) TO lv_toolbar-text.   "Push button Text
    MOVE 'Save'(100) TO lv_toolbar-quickinfo. "Push button Quick-Info
    MOVE space TO lv_toolbar-disabled. "Push button enabled
    APPEND lv_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.


  "Method User_command
  METHOD user_command.
    IF e_ucomm = ' '.

    ENDIF.
  ENDMETHOD.                    "USER_COMMAND

ENDCLASS.                    "lcl_report IMPLEMENTATION

*Finally, the Events of the program execution
INITIALIZATION.
* object for the report
  CREATE OBJECT lo_report.
* generate output
  lo_report->generate_output( ).

START-OF-SELECTION.
* Get data
  lo_report->get_data( ).
