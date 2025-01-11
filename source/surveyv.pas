type
     str16 = string[16];
     str20 = string[20];
     str25 = string[25];
     str50 = string[50];
     str65 = string[65];
     str80 = string[80];
     str255 = string[255];

    point = record
              from_pt   : integer;    { pt.#0 if enter N,E }
                bs_pt   : integer;    { back sight pt# to turn hz_ang from zero }
              code      : integer;    { 0-asz/bear, 1-hz_ang/right 2-hz_ang/left }
              descrip   : str20;
              Setup     : boolean;    { TRUE if this is a setup pt. }
              aszmith   : real;       { In radian measure }
              hz_ang    : real;       { horizontal angle }
              bs_ang    : real;
              f_dist    : real;       { Back Sight Angle }
              extra1    : real;
              distance  : real;
              north     : real;
              east      : real;
              HI        : real;       { if set up point }
              vert_ang  : real;
              rod       : real;
              elev      : real;
            end;
      sort_xyp = record
                  x,y: real;
                  el : real;
                  p  : integer;
                end;

     lin1_rec  = record
                     lt,pen : byte;
                     lab    : char;
                 end;
     alt_pt    = record
                    alt_x : real;
                    alt_y : real;
                    alt_z : real;
                    alt_d : string[20];
                 end;


var
      i,j       : integer;
      pt_file   : file of point;   { file of survey data points }
      pt_file2  : file of point;
      inf       : text;
      led_file  : text;
      sort_file : file of sort_xyp;
      pt_rec    : point;
      pt_rec0   : point;
      no_pts    : integer;         { number of point in file }
      no_pts2   : integer;         { at start up time }
      asz_err   : boolean;         { TRUE if bad aszmith string }
       pt_err   : boolean;         { TRUE if bad point numbers }
      file_flag : boolean;         { TRUE if file open }
      fn,fn2    : string[30];
      fn3,fn4   : string[30];
      fn5,fn6   : string[30];
      fn7,fn8   : string[30];
      bs_edit   : boolean;
      last_from : integer;
      last_descrip : string[20];
      last_asz     : array[1..10] of real;
      last_alt_asz : array[0..100] of real;
      last_alt_loca: integer;
      last_des     : array[1..10] of str20;
      last_int     : array[1..10] of integer;
      last_alt_int : array[0..100] of integer;
      last_alt_loci: integer;
      last_alt_real: array[0..100] of real;
      last_alt_locr: integer;
      last_real    : array[1..10] of real;
      last_lin1    : array[0..10] of lin1_rec;
      last_lin2    : array[0..10] of str20;
      recalc       : boolean;
      pt_elev      : boolean;
      xo,yo     : real; { digitizer Setup variables }
      no,eo     : real;
      dx_scale  : real;
      dy_scale  : real;
      skew_ang  : real;
      last_but  : integer;   { last button pressed on digitizer pad }
      pt_found  : integer;   { pt# digitized, 0 if no pt in range }
      pt_found_sort:integer;
      xo_men     : real;           { menu setup variables }
      yo_men     : real;
      skew_men   : real;
      box_x      : integer;
      box_y      : integer;
      x_box_size,
      y_box_size : real;
      men_arr    : array[1..30,1..70] of byte;
      men_but    : integer;
      men_but_flg: boolean;
      men_x,men_y: integer;
      dig_men_flg: boolean;
      dist_type : char;
      last_dist_type : char;
      demo     : boolean;
      large    : boolean;
      last_pt_type : byte;
      dig_des      : string[20];
      dig_shape    : boolean;
      dig_type     : byte; { 1-HI 2-Summa }
      dig_98       : array[1..10,1..3] of integer; { byte, AND, SHL }
      dig_99       : array[1..3] of byte;  { to store ASCII Frame data }
      dig_div_fact : real; { division factor }
      script_file  : array[0..10] of text;
      act_script   : byte; { active script file }
      learn        : boolean;
      lrn_file     : text;
      option_set   : string[200];
      con_flag     : boolean;
      add_flag     : integer; { 1= add 2= subtract }
      roll_flag    : boolean;
      cogo_err     : boolean;
      con_color    : byte;
      int_os       : byte;
      real_os      : byte;
      asz_os       : byte;
      act_if       : array[0..10] of byte;
      if_arr       : array[0..10,0..10] of boolean;
      else_arr     : array[0..10,0..10] of boolean;
      act_label    : integer;
      as_br_flg    : boolean;  { azimuth bearing output flag }
      alt_pt_rec0  : alt_pt;
      alt_pt_rec   : alt_pt;
      alt_pt_file  : file of alt_pt;
      alt_flag     : boolean;

      s,s2         : str25;    { strings for string input }
      x,y,k        : integer;
      m            : integer;
      r2           : real;
      r2_flag      : boolean;  { true if input_real with letters codes }
      inp_err      : integer;
      key          : integer;
      men_key_but  : integer;
      but1_flag    : boolean;
      vert_type    : char;   { V ertical Angle  D elta elevation }
      vert_type2   : char;   { A verage Shots key code in input_vert }
      de_display   : real;   { value computed in display_rec }
      EDM_const    : real;
      com_drv      : integer; { drive where command.com is located }
      f_keys       : array[1..4] of string[79]; { help for function keys }
      script_no    : integer;  { no from function key }
      shell_str    : string[10]; { shell string from settings.cfg F keys }
      reg_disp_flg : boolean;
      des_disp_flg : boolean;
      nk,nj        : integer;   { new k values for general use purpose }
      dig_exit_arr : array[1..20] of byte; { Acad reentry dig command string }

      max_srt_pts  : integer;  { 3200 maximum # of pts to sort due to heap/stack restrictions }

const
     press = '...Press Any Key';
