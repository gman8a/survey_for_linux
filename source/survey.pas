program SURVEY; (*** (c) by: Gary Argraves - 8903.05 ***)

{$I Direct}   { Compiler directives }

{$IFDEF small_edit} {$M $5000,0,$A000} {$ELSE} {$M $5000,0,$12000} {$ENDIF}

{$O+} { overlay are allowed }
{$S+} { stack checking for sort routine }

{$undef make_line}
{$undef legal_descrip}
{$undef DXF}
{$undef contour}
{$undef vert_profile}
{$undef acad_script}

uses crt,basics2,
     survey0,
     survey1,survey11,survey12,survey13,
     survey2,survey22,
     survey3,survey31,
     survey4,survey41,
     survey5,
     survey6,survey7,
     survey8,survey81,survey82,survey83,survey84,survey85,
     survey9,survey91,survey92;
     

begin { ***** M a i n   L i n e ***** }
  start;
  if file_flag then begin
    init_set;  prn_set(0);  set_menu(99,'CAD');
//    if catch(Exception) = ExceptionUsed then alarm(23,2);
    repeat
      menu;
      case (pos(option,option_set) shr 1)+1 of
         1:add_point;
         2:edit_pt;
         3:descrip_ed;
       4,5:line_line;
         6:line_arc;
         7:arc_arc;
         8:pt_pt;
         9:offset;
        10:area;
        11:curve;
        12:rot_tran;
        13:balance;
        14:print_pt_data;
        15:pc_ts_exit;
        16:line_arc_tan;
        17:settings;  { all log_settings are read from file: settings.cfg }
        18:browse;
        19:vert_curv;
        20:insert;
//        21:begin flush_pt_file; plot_menu(fn7+'DR'+'?',''); end;
        22:stake;
        23:station;
        24:Tog_printer;
        25:set_dig;
        26:move;
        27:dig_add;
        28:begin mode('TAG Printer'); tag_prn(fn+': '+pt_rec0.descrip); end;
{$IFDEF  make_line}     { make a line file with digitizer or but commands }
//        29:draw1;   { make shape }
{$ENDIF}
        30:ReCalc:=not ReCalc;
        31:side_shot(1,'Normal');
        32:side_shot(4,'MAP_CHK');
        33:protect(2);
        34:protect(1);
        35:protect(5);
        36:protect(3);
        37:protect(4);
        38:compare;
        39:ang_math;
        40:get_pt;
{$IFDEF DXF}
        41:make_DXF;
{$ENDIF}
        42:begin mode('Flushed Pts to Disk'); flush_pt_file; end;
{        43: cursor must be set by edit of file: settings.cfg --> cursor(0); }
        44:side_shot(5,'ELEV. REV.');
        45:revise_pt;
        46:Side_shot(2,'TOPO');
        47:Side_shot(3,'QUICK');
//        48:com_menu('');
        49:dup_pt_file;
        50:prn_set(999);
        51:{ co_down moved into com work } ;
{$IFDEF  make_line}     { make a line file with digitizer or but commands }
        52:begin if not dig_flag then set_dig;
                  set_menu(99,'CAD');
                  make_ln;
            end;
{$ENDIF}
        53:begin dig_menu;
             case response of
               'C':set_menu(0,'CAD');
               'L':set_menu(0,'LEGAL');
               else menu_test;
             end{case};
           end;
{$IFDEF legal_descrip}
          54:begin
               if not dig_flag then set_dig;
               set_menu(99,'LEGAL');
               legal_des;
            end;
{$ENDIF}
(*         55:begin
               if not dig_flag then set_dig;
               set_menu(99,'CAD');
               profile;
             end; *)
{$IFDEF SDR2}
        56:sdr_convert;
{$ENDIF}
        57:Ascii_out;
        58:road_arc;
        59:Snap_arc;
        60:learn_init;
        61:lrn_end;
        62:run;
        63:reg_flip;
        64:iff;
     65,66:if_else;
        67:Triangle;
     68,69:jump;
        70:shell;
        71:draw;
        72:begin mode('PC-TS Version'); gotoxy(1,7); pcts_id_tag; end;
        73:El_Trans;
        74:ascii_in;
//        75:simple;
{$IFDEF  contour}            { Semi Automated Contouring with dig by Joe Rieng }
        76:contour;
{$ENDIF}
{$IFDEF vert_profile}        { Verticle Profile, Verticle Curve by Joe Rieng }
        77:profile;
        78:vertprof;
{$ENDIF}
        79:no_pts_grab;
{$IFDEF acad_script}
        80:lnj;
{$ENDIF}
        81:field_cad;
        82:find;
{        83:clock; }
      end{case menu};
//      if catch(Exception) = ExceptionUsed then alarm(23,2); { edit use catch }
    until option='Ex';
  end;
  done;
//  if plot then halt(9);
end.
