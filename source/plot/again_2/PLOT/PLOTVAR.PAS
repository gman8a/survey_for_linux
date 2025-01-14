type
    point = record
              from_pt   : integer;    { pt.#0 if enter N,E }
                bs_pt   : integer;    { back sight pt# to turn hz_ang from zero }
              code      : integer;    { 0-asz/bear, 1-hz_ang/right 2-hz_ang/left }
              descrip   : string[20];
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
      alt_pt    = record
                    alt_x : real;
                    alt_y : real;
                    alt_z : real;
                    alt_d : string[20];
                 end;

     str16 = string[16];
     str20 = string[20];
     str25 = string[25];
     str50 = string[50];
     str65 = string[65];
     str80 = string[80];
     all_char = set of ' '..'}';
var
      i         : integer;
      pt_file   : file of point;   { file of survey data points }
      pt_file2  : file of point;
      led_file  : text;
      sort_file : file of sort_xyp;
      pt_rec    : point;
      pt_rec0   : point;
      no_pts    : integer;         { number of point in file }
      no_pts2   : integer;         { at start up time }
      option    : string[2];       { Last option choosen }
      asz_err   : boolean;
      pt_err    : boolean;
      file_flag : boolean;         { TRUE if file open }
      fn,fn2    : string[30];
      fn3,fn4   : string[30];
      fn5,fn6   : string[30];
      fn7,fn8   : string[30];
      pt_elev   : boolean;
      xo,yo     : real; { digitizer Setup variables }
      no,eo     : real;
      dx_scale  : real;
      dy_scale  : real;
      skew_ang  : real;
      demo      : boolean;
      cur_file  : text;
      out_file  : text;
      mul_arr   : array[1..100] of integer;
      polly_cnt : integer;
      p4        : integer;
      dig_des   : str20;
      lc        : char;
      do_it     : boolean;
      m_sf      : real;
      plt_x_mf,
      plt_y_mf      : real;
      tag_flag      : boolean;
      dbl_ln_len    : real;
      alt_pt_rec0  : alt_pt;
      alt_pt_rec   : alt_pt;
      alt_pt_file  : file of alt_pt;
      alt_flag     : boolean;
      sheet        : integer;
