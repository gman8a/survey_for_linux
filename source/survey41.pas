{$F+,O+}
unit survey41;
interface
uses crt,survey0,basics2,survey13;

{$IFDEF  make_line}        { make a line file with digitizer or but commands }
procedure make_ln;
procedure draw1;
{$ENDIF}

implementation

{$IFDEF  make_line}        { make a line file with digitizer or but commands }
procedure make_ln;
 type
   no_set = set of 1..255;

var
   outf      : text;
   x,y,x1,y1 : integer;
   lc        : char;
   marker    : integer;
   chr_size  : integer;
   mark_size : integer;
   mark_pos  : integer;
   mark_lab  : str20;
   char_ang  : integer;
   p1,p2,
   p3,p4     : integer;
   s         : string[80];
   i,j       : integer;
   op_but,b1 : integer;
   mul_arr   : array[1..150] of integer;  { array of MULTI Lines }
   p_cnt     : integer;
   dlab      : string[25];
   look_file : file of lin1_rec;
   n1,e1     : real;
   n2,e2     : real;
   asz1      : str16;
   d1        : real;
   pt_rec    : point;
   word_look : string[5];

procedure  msg2(i:integer; s:str80);
 var
   x,y : integer;
   begin
     whereXY(x,y);
     gotoxy(i,24); clreol;
     screen(white,red);
     write(' ',s,' ');
     screen(white,black);
     gotoxy(x,y);
   end;

  procedure display_lin1;
    var
     j,x,y : integer;
     begin
          whereXY(x,y); gotoxy(1,23); clreos;
          for j:=1 to 9 do
           begin
             screen(white,green);
             case j of
               4:gotoxy(1,24);
               7:gotoxy(1,25);
             end{case};
             with last_lin1[j] do
               write(' LT',lt:2,' Pen',pen:2,' Lab ',lab,' ');
             textbackground(black);
             write('  ');
             case j of
               3:write('Use KeyPad');
               6:write('* DEFINE');
             end{case}
           end;
         write('# Null');
         screen(white,black);
         gotoxy(x,y);
     end;

procedure get_but(x,y,bn:integer; var b:integer; s:no_set);
  begin repeat gotoxy(x,y); clreol;
               if bn=2 then b:=but2 else b:=but1;
        until b in s;
  end;

procedure  define_lin1;
  var
    b1        : integer;
    x1,y1     : integer;
    i         : integer;
    pen,lin   : integer;
    lab1      : char;

const
  lab_char :array[1..12] of char = 'ABDILNOPSTVZ';

  begin
    whereXY(x1,y1);
    writeln;
    write('Line_Type 00-12 '); get_but(wherex,wherey,2,lin,[0..12]);
    write(' Pen 1-9 ');         get_but(wherex,wherey,1,pen,[1..9]);
    write(' Label A0B1 L4 N5 D2I3O6 P7 S8T9 V*Z# ');
    get_but(wherex,wherey,1,b1,[0..11]);
    lab1:=lab_char[b1+1];
    msg2(1,'Mem.Reg.1-9 or 0 for 1 Time');
    write(' Store 0-9 '); get_but(wherex,wherey,1,i,[0..9]);
    last_lin1[i].lt:=lin;
    last_lin1[i].pen:=pen;
    last_lin1[i].lab:=lab1;
    last_lin1[10]:=last_lin1[i];
    gotoxy(x1,y1);
  end;

procedure get_look;
  begin
    display_lin1;
    write('  Look ');
    get_but(wherex,wherey,1,b1,[1..10,99]);
    if b1=99 then define_lin1
    else last_lin1[10]:=last_lin1[b1];
  end;

procedure get_marker;
  var
   s2 : byte;
  begin
    msg2(1,'Marker Type 00-13 ==> Last Marker');
    s2:=marker;
    str(marker:4,s); s:='Last Marker ='+s;
    msg(1,s);
    write('  Marker ');
    get_but(wherex,wherey,2,marker,[0..13,98]);
    if marker=98 then
        begin
          marker:=s2;
          write(^H^H,s2:2);
        end;
  end;

procedure get_mark_pos;
  begin
    msg2(1,'Marker Pos. On Line 0-3 ?');
    write('  Mark_Pos ');
    get_but(wherex,wherey,1,mark_pos,[0..3]);
  end;

procedure get_chr_size;
  var
    x : integer;
    s2 : byte;
  begin
    msg2(1,'Char. Size 100=1" ==> Last Size');
    s2:=chr_size;
    str(chr_size:4,s); s:='Last Char Size ='+s;
    msg(1,s);
    writeln;
    write('  Size:'); x:=wherex;
    get_but(x,wherey,2,chr_size,[5..99]);
    if chr_size=99 then
      begin
        msg2(1,'Set Size with 2 Menu #''s');
        gotoxy(x,y); clreol;
        write('##',^H^H); chr_size:=dig_num;
      end;
    if chr_size=98 then chr_size:=s2;
    write('  O.K. Yes/No ? ');
    get_but(wherex,wherey,1,b1,[0,1]);
  end;

procedure get_mark_size;
  var
    x : integer;
    s2 : byte;
  begin
    msg2(1,'Marker Size 1 unit=.02" ==> Last Size');
    s2:=mark_size;
    str(mark_size:4,s); s:='Last Marker Size ='+s;
    msg(1,s);
    write('  Size:'); x:=wherex;
    get_but(x,wherey,2,mark_size,[0..255]);
    case mark_size of
      99:begin
           msg2(1,'Set Size with 2 Menu #''s');
           gotoxy(x,y); clreol;
           write('##',^H^H); mark_size:=dig_num;
         end;
      98:begin
           mark_size:=s2;
           write(^H^H,s2:2);
         end;
    end{case};
  end;

procedure get_look_file;
  var i : integer;
   begin
     assign(look_file,'look.cfg');
     if exist('look.cfg') then
       begin
         reset(look_file);
         for i:=1 to 10 do read(look_file,last_lin1[i]);
       end;
   end;

procedure get_ptr;
  var   x : integer;

   begin
     x:=wherex;
     msg2(1,'Point From - Start/End/None ?'); p4:=but2;

     case p4 of 16:word_look:=' S';
                18:word_look:=' E';
                else word_look:=' ';
     end{case};

     gotoxy(x,wherey); clreol; write(word_look);
     if p4 in [16,18] then
       begin
         msg2(1,'Digitize Pointer');
         write_dig(p4,' PointTo:');
       end
     else p4:=0;
     write(' Char_Look:'); x:=wherex;
     msg2(1,^G+'Box Italic Underline None ? ');

     repeat
       case but2 of
         10:word_look:=word_look+'B';
         12:word_look:=word_look+'I';
         14:word_look:=word_look+'U';
       end{case};
       gotoxy(x,wherey); clreol; write(word_look);
     until men_but in [98,99];

     if word_look=' ' then word_look:=' N';
   end;

  var sfn       : str25;
      no_pts3   : integer;
      np        : integer;
begin
   if option='Ml' then mode('Modify Line File with Dig. Input')
   else mode('Make Shape File Coor.');
   writeln; writeln;
   lc:='#';
   no_pts3:=no_pts; { do not use }
   get_look_file;
   if option='Ms' then
     begin
       path:='*.SHP'; sfn:=read_fn('',13,8,'Shape (ex Trench)',true);
       np:=no_pts; { for shape pt# calc }
       if sfn<>'' then
         begin
           sfn:=sfn+'.SHP';
           if exist(sfn) then
             begin
               quest(0,0,'File Exists, Overwrite (Y/N) ? ',['Y','N'],false);
               if response='Y' then dig_shape:=true;
             end
           else dig_shape:=true;
         end;
       if dig_shape then
         begin assign(inf,sfn); rewrite(inf);
               writeln; writeln(^G,'Shape ORIGIN ==> 1st Pt. Dig. NOW');
         end;
     end{ if 'Ms'}
   else {'Ml'}
     begin
       asz1:=get_dir(fn3+'?',false); write('Last char. of Line File: ',fn3);
       quest(0,0,' ? ',[' ','0'..'9','A'..'Z','a'..'z'],false); writeln;
       lc:=response; np:=0;
       if exist(fn3+lc) then begin assign(outf,fn3+lc); append(outf); end;
     end;
   if dig_shape or exist(fn3+lc) then
     begin
       if dig_shape then
         begin
           assign(outf,fn3+'!'); rewrite(outf);
           writeln(outf,16:2,dx_scale:5:0,0:5,1:3,0:3,1:3);  { set at_scale }
         end;
       purge(dig_port);
       chr_size:=10;
       mark_size:=4;
       mark_lab:='';
       marker:=4;
       repeat
         gotoxy(1,15); clreos; write('COMMAND:'); op_but:=but2;
         whereXY(x,y);
         gotoxy(1,y); clreol;
         case op_but of
            0,1:begin
                   dig_des:='LINE';
                   write_dig(p1,'LINE  From:');
                   write_dig(p2,' To:');
                   get_mark_pos;
                   get_look;
                   with last_lin1[10] do
                     begin
                       writeln(outf,op_but:2,p1-np:5,p2-np:5,mark_pos:3,lt:3,pen:3,' ',lab);
                       write('   ',lt:3,pen:3,' ',lab);
                     end;
                end;
              2:begin
                   dig_des:='ARC';
                   write_dig(p1,'ARC  P.C:');
                   write_dig(p2,' P.T:');
                   write_dig(p3,' Cen:');
                   get_look;
                   with last_lin1[10] do
                     begin
                       writeln(outf,op_but:2,p1-np:5,p2-np:5,p3-np:5,lt:3,pen:3,' ',lab);
                       write('   ',lt:3,pen:3,' ',lab);
                     end;
                end;
              3:begin { draw marker }
                   dig_des:='MARKER';
                   write_dig(p1,'MARKER Where:');
                   write(' Char.Ang:Pt?');     get_xy(e1,n1);
                   get(p1,pt_rec);
                   with pt_rec do ptpt(east,north,e1,n1,d1,asz1);
                   p2:=round((5/2*pi-asz_rad(asz1))*180/pi);
                   if p2>360 then p2:=p2-360;
                   write(^H^H^H,p2:4,chr(248));
                   get_mark_size;
                   get_marker;
                   mark_lab:=pt_rec.descrip;
                   write(' Lab:'); input_des(mark_lab);
                   if mark_lab='?' then mark_lab:=' ';
                   writeln(outf,op_but:2,p1-np:5,p2:5,mark_size:5,marker:5,2:5,' ',mark_lab);
                end;
             23:begin { set marker }
                   dig_des:='SET MARK';
                   write('SET MARK');
                   write(' Label Angle: Pt#1?'); get_xy(e1,n1);
                   write(^H^H,'2?'); get_xy(e2,n2);
                   ptpt(e1,n1,e2,n2,d1,asz1);
                   p2:=round((5/2*pi-asz_rad(asz1))*180/pi);
                   if p2>360 then p2:=p2-360;
                   write(^H^H^H^H^H,p2:3,chr(248));
                   get_mark_size;
                   get_marker;
                   writeln(outf,op_but:2,0:5,0:5,mark_size:5,marker:5,p2:5);
                end;
         4,5,10:begin
                   dig_des:='POLY';
                   if op_but=10 then write('POLY  ')
                   else begin dig_des:='TRAV'; write('TRAV  '); end;
                   x:=wherex;
                   write(' 1-Existing 2-New Pts'); x1:=wherex;
                   get_but(x1,y,1,b1,[1,2]);
                   gotoxy(x,y); clreol;
                   case b1 of
                     1:begin
                        write_dig(p1,'From:');
                        write_dig(p2,'  To:');
                       end;
                     2:begin
                          msg2(1,'Dig.NEW Pts Only!');
                          men_but:=0;
                          p1:=dig_point;
                          repeat p2:=dig_point; until (last_but=10) or (men_but in [10,11]);
                          gotoxy(x,y); clreos;
                          write('From:Pt#',p1:4,'  To:Pt#',p2:4);
                       end;
                   end{case};
                   get_mark_pos;
                   get_look;
                   with last_lin1[10] do
                     begin
                       writeln(outf,op_but:2,p1-np:5,p2-np:5,mark_pos:3,lt:3,pen:3,' ',lab);
                       write('   ',lt:3,pen:3,' ',lab);
                     end;
                end;
              8:begin { words plot oriented }
                   dig_des:='WORDS';
                   msg2(1,'Plot Oriented');
                   write_dig(p1,'WORDS  Where:');
                   write_dig(p2,' Dir1:');
                   write_dig(p3,' Dir2:');
                   write(' Ptr.:');
                   get_ptr;
                   get_chr_size;
                   if b1=1 then begin
                     writeln(outf,op_but:2,p1-np:5,p2-np:5,p3-np:5,chr_size:4,max(0.0,p4-np):5:0,word_look);
                     writeln(outf,' Words//'); end;
                end;
              9:begin
                   dig_des:='WORDS';
                   msg2(1,'Page Oriented');
                   write_dig(p1,'WORDS  Where:');
                   write(' Ptr.:');
                   get_ptr;
                   get_chr_size;
                   if b1=1 then begin
                     writeln(outf,op_but:2,p1-np:5,max(0.0,p4-np):5:0,0:5,chr_size:5,0:3,word_look);
                     writeln(outf,' Words//'); end;
                end;
             11:begin { ellipse }
                  dig_des:='ELLIPSE';
                  write_dig(p1,'ELLIPSE  End#1:');
                  write_dig(p2,' End#2:');
                  write(' Top:');           get_xy(e1,n1);
                  get(p1,pt_rec);
                  with pt_rec do ptpt(east,north,e1,n1,d1,asz1);
                  pt_to_pt(p1,p2,e1,asz1); e1:=e1/2;
                  d1:=sqrt(d1*d1-e1*e1)/e1*100;
                  get_look;
                  with last_lin1[10] do
                     begin
                       writeln(outf,op_but:2,p1-np:5,p2-np:5,d1:5:0,lt:3,pen:3);
                       write('   ',lt:3,pen:3);
                     end;
                end;
             12:begin
                   dig_des:='DIM LN';
                   write_dig(p1,'DIMLN  From:');
                   write_dig(p2,' To:');
                   write(' Enter Dim. Lab ? '); read(dlab);
                   get_chr_size;
                   writeln(outf,op_but:2,p1-np:5,p2-np:5,1:3,chr_size:4,1:3,' ',dlab);
                end;
             13:begin  { rectangle plot oriented }
                   dig_des:='RECTANGLE';
                   msg2(1,'Plot Oriented');
                   write_dig(p1,'RECT   Where:');
                   write_dig(p2,' X-Dir1:');
                   write_dig(p3,' X-Dir2:');
                   write(' X-Len:Pt?');   get_xy(e1,n1);
                   get(p1,pt_rec);
                   with pt_rec do ptpt(east,north,e1,n1,d1,asz1);
                   e1:=d1/dx_scale*100;
                   write(^H^H^H,e1:3:1,''' Y-Len:Pt?');   get_xy(e2,n2);
                   with pt_rec do ptpt(east,north,e2,n2,d1,asz1);
                   e2:=d1/dx_scale*100;
                   write(^H^H^H,e2:3:1,'''');
                   get_look;
                   with last_lin1[10] do
                     writeln(outf,16:2,dx_scale:5:0,0:5,1:3,lt:3,pen:3);  { set look }
                   writeln(outf,op_but:2,p1-np:5,p2-np:5,p3-np:5,e1:5:0,e2:5:0,' ');
                end;
             14:begin  { rectangle page oriented }
                   dig_des:='RECTANGLE';
                   msg2(1,'Page Oriented');
                   write_dig(p1,'RECT   Where:');
                   write(' X-Len:Pt?');   get_xy(e1,n1);
                   get(p1,pt_rec);
                   with pt_rec do ptpt(east,north,e1,n1,d1,asz1);
                   e1:=d1/dx_scale*100;
                   write(^H^H^H,e1:3:1,''' Y-Len:Pt?');   get_xy(e2,n2);
                   with pt_rec do ptpt(east,north,e2,n2,d1,asz1);
                   e2:=d1/dx_scale*100;
                   write(^H^H^H,e2:3:1,'''');
                   get_look;
                   with last_lin1[10] do
                     writeln(outf,16:2,dx_scale:5:0,0:5,1:3,lt:3,pen:3);  { set look }
                   writeln(outf,op_but:2,p1-np:5,0:5,0:5,e1:5:0,e2:5:0,' ');
                end;
              18:begin { SHAPE plot oriented }
                   dig_des:='SHAPE';
                   msg2(1,'Plot Oriented');
                   write_dig(p1,'SHAPE  Where:');
                   write_dig(p2,' Dir1:');
                   write_dig(p3,' Dir2:');
                   write(' File:'); read(asz1);
                   writeln(outf,op_but:2,p1-np:5,p2-np:5,p3-np:5,100:4,0:5,' ',asz1);
                end;
         6,7,20:begin
                   dig_des:='MULTI';
                   if op_but=20 then
                     begin write('M_POLY'); dig_des:='M_POLY'; end
                   else write('MULTI ');
                   whereXY(x1,y1);
                   writeln('  Dig. Pts. Use Last Pt');
                   p_cnt:=0;
                   for i:=1 to 50 do mul_arr[i]:=0;
                   men_but:=0;
                   repeat
                     p_cnt:=p_cnt+1;
                     mul_arr[p_cnt]:=dig_point;
                   until (last_but in [10,11]) or (men_but in [10,11]);
                   writeln; get_mark_pos; get_look;
                   gotoxy(1,y1); clreos;
                   i:=1; while mul_arr[i]>0 do i:=i+1;
                   if dig_shape then for j:=1 to i-1 do mul_arr[j]:=mul_arr[j]-np;
                   if op_but=20 then begin mul_arr[i]:=-1; i:=1; end else i:=2;
                   if p_cnt>1 then  { write line command to set look }
                     with last_lin1[10] do
                       begin
                         if op_but<>20 then begin
                           writeln(outf,op_but-6:2,mul_arr[1]:5,mul_arr[2]:5,mark_pos:3,lt:3,pen:3,' ',lab);
                           write('LINE  ',mul_arr[1]:5,mul_arr[2]:5,mark_pos:3,lt:3,pen:3,' ',lab);
                         end
                         else begin
                           writeln(outf,16:2,dx_scale:5:0,0:5,1:3,lt:3,pen:3);  { set look }
                           write('SETVAR',0:5,2:5,1:3,lt:3,pen:3);     { set look }
                         end;
                         writeln; clreos; gotoxy(1,25); writeln;
                         gotoxy(1,y1);
                       end;
                   while (mul_arr[i+1]<>0) or (mul_arr[i]=-1) do
                     begin
                       writeln(outf,op_but:2,mul_arr[i+0]:5,mul_arr[i+1]:5,
                                             mul_arr[i+2]:5,mul_arr[i+3]:5,
                                             mul_arr[i+4]:5,' ',
                                             last_lin1[10].lab);
                       if op_but=20 then write('M_POLY')
                       else write(  'MULTI ');
                       write(                mul_arr[i+0]:5,mul_arr[i+1]:5,
                                             mul_arr[i+2]:5,mul_arr[i+3]:5,
                                             mul_arr[i+4]:5,' ',
                                             last_lin1[10].lab);
                       writeln; clreos; gotoxy(1,25); writeln;
                       gotoxy(1,y1);
                       i:=i+4; if op_but=20 then i:=i+1;
                     end;
                end;
         end{case};
         writeln; gotoxy(1,25); writeln;
       until op_but=121;
       if dig_shape then
         begin
           writeln(inf,0.0:10:4,0.0:10:4,' *** END COOR.LIST ***');
           reset(outf);
           while not eof(outf) do begin readln(outf,s); writeln(inf,s); end;
           close(outf); erase(outf); close(inf);
           set_no_pts(no_pts3);
         end
       else close(outf);
     end
   else cnff(fn3+lc+' or /Make NO Shape/');
   rewrite(look_file);
   for i:=1 to 10 do write(look_file,last_lin1[i]);
   close(look_file);
   dig_des:='?';
   dig_shape:=false;
end;

procedure make_shp;
  var
    sfn    : string[25];
    sf     : text;
    x,y    : real;
    i      : integer;
    no_pts3 : integer;
  begin
    no_pts3:=no_pts;
    mode('Make Shape File Coordinates');
    writeln;
    path:='*.SHP'; sfn:=read_fn('',13,8,'Shape (ex Trench)',true);
    if sfn<>'' then
      begin
        sfn:=sfn+'.SHP';
        if exist(sfn) then
          quest(0,0,'File Exist, Overwrite (Y/N) ? ',['Y','N'],false)
        else response:='Y';
        if response='Y' then
          begin
            assign(sf,sfn);
            rewrite(sf);
            gotoxy(1,3);
            writeln(' ...Press # Key to End Digitizing...');
            i:=1;
            repeat
              get_xy(x,y);
              writeln(i:3,x:9:3,y:9:3);
              writeln(sf, x:9:3,y:9:3);
              i:=i+1;
            until (last_but=11) or (men_but in [10,11]);
            write(sf,0.0:9:3,0.0:9:3);
            close(sf);
          end;
      end;
    set_no_pts(no_pts3);
  end;

procedure draw1;
  begin
     if not dig_flag then set_dig;
     gotoxy(1,12); clreos;
     quest(0,0,'[J]ust Coor. [L]ine file ?',['J','L'],false);
     if response='J' then make_shp else make_ln;
  end;
{$ENDIF}

end.

