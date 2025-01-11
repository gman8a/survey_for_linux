{$F+,O+}
unit survey7;
interface

{$I Direct}   { Compiler directives }

uses dos,crt,survey0,basics2;

procedure dup_pt_file;
procedure menu_test;
{$IFDEF legal_descrip} procedure legal_des; {$ENDIF}

implementation

procedure dup_pt_file;
  var
    i : integer;

   begin
     mode('Duplicate Point File');
     if not alt_flag then begin
       go_write(19,15,'==> Duplicating Point File.   Record Count =  ');
       assign(pt_file2,fn2);
       rewrite(pt_file2);
       for i:=0 to no_pts do  { Duplicate file }
         begin
           gotoxy(70,15); write(no_pts-i:4);
           get(i,pt_rec);
           write(pt_file2,pt_rec);
         end;
       close(pt_file);
       close(pt_file2);
       writeln;
       i:=48;
       repeat inc(i); fn6[length(fn6)]:=chr(i); until not exist(fn6);
       assign(pt_file,fn);  rename(pt_file,fn6);
       writeln;
       writeln('Name of the Back Up File: ',fn6);
       assign(pt_file,fn2); rename(pt_file,fn);
       reset(pt_file);
       gotoxy(17,20); clreol;
     end
     else writeln(^G,' Can NOT Backup Alternate Pt. Files');
   end;

procedure menu_test;
  var
    x,y : real;
    b1 : integer;
    f : boolean;
  begin
    mode('Test Digitizer Menu Feature'); writeln('  # to Exit');
    f:=dig_flag;
    dig_flag:=true;
    men_but:=0;
    repeat
      dig_get(b1,x,y);
      if men_but_flg then writeln('Menu Option =',men_but:4);
    until (b1=11) or (men_but in [10,11,121]);
    dig_flag:=f;
  end;

{$IFDEF legal_descrip}       { include legal description dig link }
procedure legal_des;
 type str60 = string[60];
  var
    x,y       : real;
    b1,i      : integer;
    rec_cnt   : integer;
    inf       : text;
    word_file : file of str60;
    s         : str60;
    rec       : integer;
    asz       : str16;
    d         : real;
    x1,y1     : integer;
    del_xy    : array[1..2,0..50] of byte;
    del_cnt   : integer;
    pt_rec    : point;
    p1,p2     : integer;
    cen_pt    : integer;
    rad,len   : real;
    delta     : str16;
                                                  { radius, length, delta }
procedure get_arc_data(p1,p2,cen_pt:integer; var d1,s:real; var asz1:str16);
  var
    delta     : real;
    asz2      : str16;
    d2,t      : real;
    s2        : string[60];
  const
    rad_acc = 0.00001; { radian accuarcy }
  begin
     pt_to_pt(cen_pt,p1,d1,asz1);        { d1=radius}
     pt_to_pt(cen_pt,p2,d2,asz2);
     if abs(d1-d2)>0.005 then
       begin
         str(d1-d2:10:5,s2);
         s2:='*** Err-Radii not Equal ***  R1-R2='+s2;
         msg(1,s2);
       end;
     delta:=asz_rad(asz2)-asz_rad(asz1);
     while delta<0 do delta:=delta+2*pi;
     if delta>pi then delta:=2*pi-delta; { Minor Arc only }
     pt_to_pt(p1,p2,d2,asz2);            { chord length }
     asz2:=rad_bear(asz_rad(asz2));      { chord bearing }
     s:=delta*d1;                        { curve length }
     asz1:=rad_asz(delta);               { delta angle }
     if (abs(delta-pi/2)>rad_acc) and (abs(delta-pi)>rad_acc)
     then t:=tan(delta/2)*d1 else t:=d1; {d1=radius}
  end;

procedure stack_del;
  begin
    del_cnt:=del_cnt+1;
    del_xy[1,del_cnt]:=wherex; del_xy[2,del_cnt]:=wherey;
    if del_cnt>49 then del_cnt:=1;
  end;

   begin
     mode('Make Legal Description');
     del_cnt:=0;
     delta:='00-00-00';
     len:=0;
     rad:=0;
     if exist('Legal.wds') then
       begin
         write('...Making Jargan File');
         assign(inf,'legal.wds'); reset(inf);
         assign(word_file,last_drv+':LEGAL.W60'); rewrite(word_file);
         write(word_file,s); { do not want 0 record }
         rec_cnt:=0;
         while (not eof(inf)) and (rec_cnt<box_y*box_x) do
           begin
                 readln(inf,s);
                 write(word_file,s);
                 rec_cnt:=rec_cnt+1;
           end;
         writeln('   Record Count =',rec_cnt:3);
         i:=0; repeat write('='); inc(i); until i=79; writeln;
         close(inf);
         purge(dig_port);
         repeat
           dig_get(b1,x,y);
           d:=0;
           case men_but of
              1:begin { get Bearing / distance }
                    last_pt_type:=1;
                    x1:=wherex; y1:=wherey;
                    gotoxy(1,24); clreos;
                    msg(1,'Digitize Points');
                    p1:=dig_point; get(p1,pt_rec); write(' ',pt_rec.descrip,' ');
                    p2:=dig_point; get(p2,pt_rec); write(' ',pt_rec.descrip,' ');
                    pt_to_pt(p1,p2,d,asz);
                    gotoxy(x1,y1);
                    stack_del;
                    write(' ',rad_bear(asz_rad(asz)),' ',d:9:3,''' ');
                end;
              2:begin { Get Curve Data }
                    last_pt_type:=1;
                    x1:=wherex; y1:=wherey;
                    gotoxy(1,24); clreos;
                    msg(1,'Digitize Points');
                    write('P.C.:'); p1:=dig_point;
                      get(p1,pt_rec); write(' ',pt_rec.descrip,' ');
                    write(' P.T.:'); p2:=dig_point;
                      get(p2,pt_rec); write(' ',pt_rec.descrip,' ');
                    write(' Cen:'); cen_pt:=dig_point;
                      get(cen_pt,pt_rec); write(' ',pt_rec.descrip,' ');
                    get_arc_data(p1,p2,cen_pt,rad,len,delta);
                    msg(50,'Use Put Curve to View');
                    gotoxy(x1,y1);
                end;
              3:begin { Type Words In }
                      x1:=wherex; y1:=wherey;
                      gotoxy(1,24); clreos;
                      msg(1,'Type Words Using KeyBoard');
                      read(s);
                      gotoxy(x1,y1);
                      stack_del;
                      write(' ',s);
                      clreos;
                end;
              4:begin
                  stack_del;
                  writeln; { CR LF }
                end;
              5:begin { Delete last words }
                  gotoxy(del_xy[1,del_cnt],del_xy[2,del_cnt]); clreos;
                  dec(del_cnt); if del_cnt<1 then del_cnt:=1;
                end;
              6:begin
                   str(rad:9:3,s);
                   stack_del;
                   write(s,'''');
                   clreos;
                end;
              7:begin
                   stack_del;
                   write(delta);
                   clreos;
                end;
              8:begin
                   str(len:9:3,s);
                   stack_del;
                   write(s,'''');
                   clreos;
                end;
              9:begin
                   write(' ');
                end;
           end{case};
           rec:=(men_x-1)*box_y+(box_y-men_y+1);
           if (men_but_flg) and (men_but=0) and (rec in [1..rec_cnt]) then
             begin
               seek(word_file,rec);
               read(word_file,s);
               while (length(s)>0) and (s[1]=' ') do delete(s,1,1);
               while (length(s)>0) and (s[length(s)]=' ') do delete(s,length(s),1);
               stack_del;
               write(' ',s);
             end;
          if wherex>65 then writeln;
         until men_but in [121,10,11];
       end
    else cnff('LEGAL.WDS');
    close(word_file);
   end;
{$ENDIF}

end.
