unit survey13;
interface
uses crt,survey0,basics2;

procedure set_menu(i:integer;  fn:str25);
procedure set_dig;
procedure prn_set(i:integer);

implementation

procedure set_menu(i:integer;  fn:str25); begin end;
procedure set_dig;begin end;
procedure prn_set(i:integer);begin end;

{$if 1=0}
procedure set_menu(i:integer;  fn:str25);
  var
     menu_file    : text;
     x,y          : real;
     old_dig_flag : boolean;
     j        : integer;

procedure load_menu;
  var i,j : integer;
  begin
    writeln;
    if exist(fn+'.LAY') then
      begin
        assign(menu_file,fn+'.LAY');
        reset(menu_file);
        readln(menu_file,box_x,box_y,x_box_size,y_box_size,xo_men,yo_men,skew_men);
        close(menu_file);
        if exist(fn+'.MAT') then
          begin
            assign(menu_file,fn+'.MAT');
            reset(menu_file);
            for i:=1 to box_y do
              begin
                for j:=1 to box_x do read(menu_file,men_arr[j,box_y+1-i]);
                readln(menu_file);
              end;
            writeln('+++ Digitizer Menu File: ',fn,' Loaded +++');
            dig_men_flg:=true;
          end
        else cnff(fn+'.MAT');
      end
    else cnff(fn+'.LAY');
    delay(750);
  end;

   begin
     if i=0 then
       begin
         quest(0,0,'[L]oad Exist Menu   [M]ake New Menu Config.',['L','M'],false);
         if response='L' then i:=99;
         writeln;
       end;
     if i=0 then begin
       mode('Setup Parameters of Digitizer Menu'); writeln;
       gotoxy(1,3);
       write('Enter No. Boxes in X direction ? '); input_i(box_x); writeln;
       write('Enter No. Boxes in Y direction ? '); input_i(box_y); writeln;
       write('Enter X-Box Side Size in Inches  ? '); input_r(x_box_size); writeln;
       write('Enter Y-Box Side Size in Inches  ? '); input_r(y_box_size); writeln;
       writeln;
       old_dig_flag:=dig_flag;
       dig_flag:=true;
       purge(dig_port);
       write(^G,'*** Digitize LOWER LEFT Box Corner ***');  dig_get(last_but,xo_men,yo_men);
       writeln;
       write(^G,'*** Digitize LOWER RIGHT Box Corner ***'); dig_get(last_but,x,y);
       dig_flag:=old_dig_flag;
       x:=x-xo_men; y:=y-yo_men;
       if x<>0 then skew_men:=arctan(abs(y/x)) else skew_men:=pi/2;
       if x<0 then if y>0 then skew_men:=pi-skew_men else skew_men:=pi+skew_men
       else if y<0 then skew_men:=2*pi-skew_men;
       writeln;
       writeln('Skew angle of the Menu = ',rad_asz(skew_men));
       assign(menu_file,fn+'.LAY');
       rewrite(menu_file);
       writeln(menu_file,box_x:4,box_y:4,x_box_size:7:3,y_box_size:7:3,xo_men:8:4,yo_men:8:4,skew_men:11:6);
       close(menu_file);
       load_menu;
     end
     else load_menu; { open menu set file and set current parameters }
   end;

procedure set_dig;
  var
    x,y     : real;
    x2,y2   : real;
    d1,d2   : real;
    asz1,
    asz2    : str16;
    pt_rec  : point;
    in_mode : CHAR;
    p1,p2   : integer;
    f_des   : string[50];

  begin
    mode('SetUp New Sheet on Digitizer Pad');
    flush_pt_file;
  if dig_type<>0 then begin
    dig_flag:=true;
    if not c_ptr[dig_port].active then
      begin com_irq(dig_port,on); set_com(dig_port,0); end;
    c_ptr[dig_port].rec_len:=dig_bytes;
    purge(dig_port);
    response:='N';
    if exist('DIG-SET.DAT') then
      begin
        assign(led_file,'DIG-SET.DAT');
        reset(led_file);
        readln(led_file,f_des);
        readln(led_file,xo,yo,eo,no,dx_scale,dy_scale,skew_ang);
        close(led_file);
        gotoxy(1,2);
        writeln('Last Setup: ',f_des);
        quest(1,3,'Use Last Setup (Y/N) ? ',['Y','N'],false);
      end;
  if response='N' then begin
    gotoxy(1,3); clreol; write(^G,'*** Digitize Origin Point ***');
    dig_get(last_but,xo,yo);
    quest(0,0,'==>>> [P]t#   [C]oordinates ? ',['P','C'],false); writeln;
    in_mode:=response;
    case in_mode of
      'C':begin
            write('Enter Origin North coordinate ? '); input_r(no); writeln;
            write('Enter Origin East coordinate  ? '); input_r(eo);
          end;
      'P':begin
             write('Enter Pt# ? '); input_i(p1);
             get(p1,pt_rec);
             with pt_rec do begin no:=north; eo:=east; end;
          end;
    end{case};
    quest(1,7,'Orientation by  [G]rid  [A]szmith ? ',['G','A'],false);
    gotoxy(1,9);
    if response='G' then
      begin
        writeln(^G,'*** Digitize Due East of Origin ***');  dig_get(last_but,x,y);
        writeln(^G,'*** Digitize Due North of Origin ***'); dig_get(last_but,x2,y2);
        write('Enter distance from Origin to Due East Pt. ? '); input_r(d1); writeln;
        write('Enter distance from Origin to Due North Pt.? '); input_r(d2); writeln;
        x:=x-xo; y:=y-yo;
        x2:=x2-xo; y2:=y2-yo;
        if x<>0 then skew_ang:=arctan(abs(y/x)) else skew_ang:=pi/2;
        if x<0 then if y>0 then skew_ang:=pi-skew_ang else skew_ang:=pi+skew_ang
        else if y<0 then skew_ang:=2*pi-skew_ang;
        dx_scale:=d1/sqrt(x*x+y*y);
        dy_scale:=d2/sqrt(x2*x2+y2*y2);
      end
    else
      begin
        writeln(^G,'*** Digitize Point with Known Aszmith & Distance ***');
        dig_get(last_but,x,y);
        case in_mode of
          'C':begin
                write('Enter Aszmith  ? '); input_asz(asz1); writeln;
                write('Enter Distance ? '); input_r(d1); writeln;
              end;
          'P':begin
                write('Enter Pt# ? '); input_i(p2);
                get(p1,pt_rec);
                with pt_rec do begin no:=north; eo:=east; end;
                pt_to_pt(p1,p2,d1,asz1);
              end;
        end{case};
        ptpt(xo,yo,x,y,d2,asz2);
        dx_scale:=d1/d2;
        dy_scale:=dx_scale;
        d1:=asz_rad(asz1);
        d2:=asz_rad(asz2);
        x:=abs(d1-d2);
        if d1>d2 then skew_ang:=x else skew_ang:=2*pi-x;
      end;
    skew_ang:=skew_ang*180/pi;
    assign(led_file,'DIG-SET.DAT');
    rewrite(led_file);
    writeln(led_file,fn,'  ',when);
    writeln(led_file,xo,' ',yo,' ',eo,' ',no,' ',dx_scale,' ',dy_scale,' ',skew_ang);
    close(led_file);
end{new setup};
    gotoxy(1,13);
    writeln('X_Scale=',dx_scale:7:2,'feet/inch');
    writeln('Y_Scale=',dy_scale:7:2,'feet/inch');
    writeln('Shew_Ang=',skew_ang:6:2,' Deg.');
    dig_flag:=true;
    writeln;
    quest(0,0,'...Press <SPACE BAR>',[' '],false);
    last_pt_type:=1; { new points }
  end{if dig_type<>0}
  else
    begin
      writeln; writeln;
      writeln(^G,'*** NO Digitizer Connected ***');
      writeln;
      writeln('Check  DIG.CFG  file is Correct');
    end;
  end;

procedure prn_set(i:integer);
  var j        : integer;
      prn_file : text;
      s        : string[80];
  begin
    if lst_flag then begin
      if i>9 then mode('Setup Printer File: PRINT.CFG');
      writeln; writeln;
      if exist('PRINT.CFG') then
        begin
          assign(prn_file,'print.cfg');
          reset(prn_file);
          if i>9 then
            begin
              writeln('0 - Default Setup');
              writeln('1 - 10 CPI (Pica)');
              writeln('2 - 12 CPI (Elite)');
              writeln('3 - 17 CPI (Condensed)');
              writeln('4 - Alternate 1');
              writeln('5 - Alternate 2');
              writeln;
              quest(0,0,'Press Printer Setup Type No. ? ',['0','1','2','3','4','5'],false); writeln;
              writeln;
              i:=ord(response)-48;
            end;
          if i=0 then
            begin
              readln(prn_file,s);
              writeln(lst,'>>>>  ',s,'  <<<<');
              writeln(lst);
              reset(prn_file);
            end;
          while (i>=0) and (not eof(prn_file)) do begin readln(prn_file); dec(i); end;
          j:=0;
          while (not eoln(prn_file)) and (not eof(prn_file)) and (j=0) do
            begin {$I-} read(prn_file,i); {$I+}
                  j:=IOResult;
                  if j=0 then write(lst,chr(i))
                  else begin
                         readln(prn_file,s);
                         writeln('+++  Printer Setup = ',s,'  +++');
                         delay(750);
                       end;
            end;
          close(prn_file);
        end
      else cnff('PRINT.CFG')
    end
    else begin writeln; clreol; writeln('NO Print-Set, 1st TOggled ON.'); end;
  end;
{$endif}

end.
