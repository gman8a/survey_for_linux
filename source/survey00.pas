function  Keyin2: integer;   { Single-Key Input Routine (MSDOS/PCDOS) }
function  Keyin: integer;    { Get a key from the proper place  }
procedure quest(x,y :integer; q_line:str50; q_set:all_char; clr:boolean);
procedure mode(m_line:string);
procedure rotate(var x,y:real; x2,y2:real; rot_ang:real);

function  Asz_Rad (asz: str16)  : real;
function  Bear_Rad(bear :str16) : real;
function  Rad_Asz (rad: real)   : str16;
function  Rad_Bear(rad: real)   : str16;
procedure input_vert(var ss:str16; d:real; dist_type:char);
procedure input_BEAR(var ss:str16);

procedure flush_pt_file;
procedure init_pt_rec(var pt_rec:point);
procedure get3(pt:integer; var sort_rec:sort_xyp);
procedure put3(pt:integer; sort_rec:sort_xyp);
procedure add3(x1,y1,e1: real; p1:integer);
procedure get(pt:integer; var pt_rec:point);
procedure set_no_pts(i:integer);
procedure put(pt:integer; pt_rec:point);
procedure add_point;

procedure bad_pt_msg;
function  tan(a:real) :real;
procedure Calculate(var pt_rec:point);
procedure ReCalculate(start_pt : integer);
procedure display_rec(pt,pos,c1,c2:integer; pt_rec:point);

procedure edit_pt;
procedure ask_add(pt_rec:point);

procedure ptpt(x1,y1,x2,y2: real;  var d:real; var asz:str16);
procedure Pt_to_Pt(p1,p2: integer; var d:real; var asz:str16);

procedure dig_get(var but:integer; var x,y:real);
function  but1:integer;  { get button from digitizer }
function  but2:integer;
function  dig_num:integer;
procedure find_xy(var x,y:real; range:real); {search sorted point file for match}
procedure display_pt_type;
procedure get_xy(var x,y:real);
function  dig_point:integer;  { get point from digitizer }
procedure write_dig(var p:integer; s:str25);
procedure input_asz(var s:str16);
procedure Intersection(p1,p2:integer; var a1,a2:str16; var d1,d2 :real);

procedure roll_asz(s:str16);
procedure roll_real(r:real);
procedure roll_int(i:integer);

procedure get_no_str;
procedure parse_s;

procedure input_r(var r:real);
procedure input2_r(var r:real);
procedure input_i(var i:integer);
procedure input_des(var des:str20);

procedure menu_op(op_set:all_char);
implementation

procedure flush_pt_file;
  begin
    if alt_flag then  { write all pts to disk incase Error }
      begin close(alt_pt_file); reset(alt_pt_file); end
    else begin close(pt_file); reset(pt_file); end;
  end;

procedure start_comment;
  begin gotoxy(1,22); screen(white,blue); clreol; write('Comment: '); end;

{----------------------------------------------------------------------}
{             Keyin :       Key input from keyboard                    }
{----------------------------------------------------------------------}
  Function Keyin2: integer;   { Single-Key Input Routine (MSDOS/PCDOS) }
    Var
      Ch    :char;
      x,y : integer;
      cs  : string[70];

   procedure get_key;
     begin
       repeat
         ch:=ReadKey;
         if (ch<>'|') and not con_flag and learn then
           begin write(lrn_file,ch:1);
                 if ch=^M then write(lrn_file,^J:1);
           end;
         if ch='{' then {comment line}
           begin
             whereXY(x,y);
             start_comment;
             readln(cs);
             if learn and not con_flag then write(lrn_file,cs,'}');
             gotoxy(x,y);
           end
         else if ch='!' then msg(40,'User Pause')
              else if ch='$' then msg(40,'Delay Pause');
         until pos(ch,'{!$')=0;
       end;

     Begin
           get_key;
           keyin2:=ord(ch);
           if Ch = ^@ then
              begin                    { If extended key type get }
                get_key;
                keyin2 := 512 + ord(ch);
              end;
     End;

{----------------------------------------------------------------------}
{             Keyin :       Key input from file then keyboard          }
{----------------------------------------------------------------------}
  Function Keyin: integer;   { Single-Key Input Routine (MSDOS/PCDOS) }
    Var
      Ch,ch2: char;
      x,y   : integer;
      ki    : integer;
     Begin
       if (act_script=0) or con_flag then begin ki:=keyin2; keyin:=ki; end
       else begin
           if not if_arr[act_script,act_if[act_script]] then { find ENDIF 9 nested }
             begin
               repeat
                 repeat Read(script_file[act_script],Ch); until Ch='~';
                 Read(script_file[act_script],Ch);
                 if (ch=chr(act_if[act_script]+64)) and else_arr[act_script,act_if[act_script]] then { ELSE }
                   begin
                     ch:=chr(act_if[act_script]+48);
                     if_arr[act_script,act_if[act_script]]:=true;
                   end;
               until ch=chr(act_if[act_script]+48);
               if not if_arr[act_script,act_if[act_script]] then act_if[act_script]:=act_if[act_script]-1;
             end;
           repeat
             repeat
               Read(script_file[act_script],Ch);
               case ch of
                 '$':delay(1000);
                 '!':begin msg(40,press); ch2:=ReadKey; end;
               end{case};
             until pos(Ch,'$!'+^J)=0;
             if ch='{' then
               begin
                 whereXY(x,y);
                 start_comment;
                 repeat Read(script_file[act_script],Ch);
                        write(ch);
                        if ch='&' then
                          begin
                            write(^H,press); ch2:=ReadKey; end;
                 until ch='}';
                 write(^H,' ');
                 gotoxy(x,y);
               end;
           until ch<>'}';
           keyin := ord(ch); ki:=ord(ch);
           if (Ch = ^@) and (not eof(script_file[act_script])) then
              begin                               { If extended key type get }
                Read(script_file[act_script],Ch); { get next key in          }
                keyin := 512 + ord(ch);
                ki := 512 + ord(ch);
              end;
           if eof(script_file[act_script]) then
             begin
               close(script_file[act_script]);
               dec(act_script);
             end;
       end;
       case ki of
          530:begin cogo_err:=true; msg(40,'COGO-ERR'); end;
       end{case};
     End;

procedure quest(x,y :integer; q_line:str50; q_set:all_char; clr:boolean);
  var
    i    : integer;
    //c    : char;
  begin
    if x*y>0 then gotoxy(x,y);
    clreol; write(q_line);
    repeat
      if act_script=0 then
        for i:=1 to 10 do begin sound(900+i*50); delay(5); end; nosound;
          response:=upcase(chr(keyin));
          if not (response in q_set) then
            begin
              if response=^M then response:=^P;
              msg(40,'>>>'+response+' Invalid entry');
              sound(500); delay(50); nosound;
              con_flag:=true;
            end;
    until response in q_set;
    write(response);
    if clr then begin gotoxy(x,y); clreol; end;
    con_flag:=false;
  end;

procedure menu_op(op_set:all_char);
  begin
    writeln; screen(yellow,black);
    quest(0,0,'Option ? ',op_set,true);
    screen(cyan,black);
  end;
