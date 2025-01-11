{$F+,O+}
unit survey81;
interface
uses crt,survey0,basics2;

{$I Direct}   { Compiler directives }

{$IFDEF SDR2} procedure sdr_convert; {$ENDIF}

implementation

{$IFDEF  SDR2}
procedure sdr_convert;

  procedure co_down;
    var
      i,j,p1,p2 : integer;
      pt_rec    : point;
      s         : string[60];
      n,e,el    : string[10];
      p         : string[4];
      cs        : real;   { check sum }
      fn7       : str25;

  begin
     mode('Send Coordinate Data to SDR2'); writeln; writeln;
     writeln('There are ',no_pts:4,' points.');
     writeln;
     write('   Enter FROM:Pt# ? '); p1:=9999; input_i(p1);
     write('   Enter TO:Pt# ? ');   p2:=9999; input_i(p2); writeln;
     fn7:=fn2; delete(fn7,length(fn7)-2,3); fn7:=fn7+'COD';
     writeln;
     if (p2>=p1) and (p2<=no_pts) and (p1<=no_pts) then
       begin
         writeln; assign(led_file,fn7); rewrite(led_file);
         write(led_file,^A,^M,^J);
         writeln(led_file,'00NM1234567890123456870404/30/8717:00:00000000');
         writeln(led_file,'10JB',fn7);
         cs:=0;
         for i:=p1 to p2 do
           begin
             get(i,pt_rec);
             with pt_rec do
               begin
                 str(north:10:3,n); str(east:10:3,e);
                 str(elev:10:3,el); str(i:4,p);
                 while n[1]=' ' do begin delete(n,1,1); n:=n+' '; end;
                 while e[1]=' ' do begin delete(e,1,1); e:=e+' '; end;
                 while el[1]=' ' do begin delete(el,1,1); el:=el+' '; end;
                 for j:=1 to 4 do if p[j]=' ' then p[j]:='0';
                 s:='08CD'+p+n+e+el+descrip;
                 while length(s)<54 do s:=s+' ';
                 for j:=1 to length(s) do
                   begin
                     cs:=cs+ord(s[j]);
                     if cs>=65536.0 then cs:=cs-65536.0;
                   end;
                 write(led_file,s,^M,^J);
                 writeln(s);
               end;
           end;
         write(led_file,^C,cs:5:0,^M,^J);
         close(led_file);
         writeln;
         writeln('Output File: ',fn7);
       end;
  end;

  var
    fn,fn1   : string;
    i,j,k,l  : integer;

procedure sdr_pt;
  var
    pt_file  : file of point;
    pt_rec   : point;
    pt_rec2  : point;
    pt_rec0  : point;
    sdr_file : text;
    sdr_rec  : string[80];
    no_pts   : integer;

     fp,np : integer;  { from pt, no. pts.}
     ih    : real;
     des1  : string[20];
     des2  : string[20];
     pt    : integer;  { pt number }
     th    : real;     { target height }
     sd    : real;     { slope distance }
     va    : real;     { verticle angle }
     ha    : real;     { horiz. angle }
     t_pt  : integer;  { greatest traverse pt used }
     hi1   : real;     { hi at pt#1 }
     map1  : integer;  { map1 to where pt 1 is }
     de    : real;     { differance in elevation }
     diff  : real;
     file2 : text;
     el_reg: real;     { for delta el error chk }
     p1_reg,
     p2_reg     : integer;
     control_pt : integer;
     i,j        : integer;

procedure get(pt:integer; var pt_rec:point);
  begin
    if pt<=no_pts then
      begin
        seek(pt_file,pt);
        read(pt_file,pt_rec);
      end;
  end;

procedure put(pt:integer; pt_rec:point);
  begin
    seek(pt_file,pt);
    write(pt_file,pt_rec);
  end;

begin
  writeln('Converts TRANSFORM Intermidiate file (.70) to .PT file.');

  path:='*.70'; fn1:=read_fn(fn,13,8,'Transformed',true);

  if pos('.',fn1)>0 then fn1:=copy(fn1,1,pos('.',fn1)-1);
  if not exist(fn1+'.70') then
    begin writeln;
          cnff(fn1+'.70');
          exit;
    end;
  assign(pt_file,fn1+'.PT');
  assign(sdr_file,fn1+'.70');
  assign(file2,fn1+'.CHK');
  if not exist(fn1+'.PT') then rewrite(pt_file)
  else begin writeln(^G,'*** Point File Already Exists ***'); exit; end;
  write('Enter Pt. file description ? '); readln(des1);
  write('Enter No. of control pts=50 ? '); control_pt:=50; input_i(control_pt);
  control_pt:=control_pt+1;
  reset(sdr_file);
  rewrite(file2);
  init_pt_rec(pt_rec);
  init_pt_rec(pt_rec2);
  init_pt_rec(pt_rec0);
  pt_rec0.descrip:=des1;
  t_pt:=2;
  for i:=1 to control_pt do put(i,pt_rec);
  no_pts:=control_pt;
  map1:=0;
  while not eof(sdr_file) do
    begin
      readln(sdr_file,fp,np,ih,des1);          { from }
      if (fp=1) and (map1>0) then fp:=map1;
      readln(sdr_file,pt,th,sd,va,ha,des2);    { back site }
      if pt<>0 then
        begin
          de:=tan(abs(va*pi/180-pi/2))*sin(va*pi/180)*sd;
          if va>90 then de:=-de;
          diff:=ih-th+de;
          writeln(file2,fp:3,'-',pt:3,'  Diff. El.=',diff:7:3,'  dEl:',de:7:3);
          writeln(fp:3,'-',pt:3,'  Diff. El.=',diff:7:3,'  dEl:',de:7:3);
          if (fp=p2_reg) and (pt=p1_reg) then
            begin
              writeln(file2,'-------- El. Error=',diff+el_reg:7:3);
              writeln('-------- El. Error=',diff+el_reg:7:3);
              writeln;
              writeln(file2);
            end;
        end;
      get(fp,pt_rec);
      if pt_rec.hi=0 then pt_rec.hi:=ih;
      if (fp=2) and (t_pt=2) then with pt_rec do  { set start point to #2 }
        begin  { initialize }
          vert_ang:=va*pi/180;
          distance:=sd*sin(vert_ang);
          f_dist:=-sd;
          from_pt:=1;
          bs_pt:=0;
          descrip:=des1;
          code:=0;
        end;
      put(fp,pt_rec);
      init_pt_rec(pt_rec);
      with pt_rec do  { setup pt_record for side shots }
        begin
          from_pt:=fp;
          if (map1>0) and (pt=1) then bs_pt:=map1 else bs_pt:=pt;
          bs_ang:=ha*pi/180;
          code:=1; { angle right }
        end;
      if pt<>0 then
        repeat
          readln(sdr_file,pt,th,sd,va,ha,des2);
          if (pt>t_pt) or (((pt=1) or (pt=2)) and (t_pt>4)) then
             { will not reshot traverse }
           with pt_rec do
            begin
              if (pt=1) and (map1=0) then map1:=t_pt+1;
              if ((pt=1) or (pt=2)) and (t_pt>4) then pt:=t_pt+1;
              if pt<control_pt then
                begin
                  setup:=true;
                  if pt>t_pt then t_pt:=pt;
                  de:=tan(abs(va*pi/180-pi/2))*sin(va*pi/180)*sd;
                  if va>90 then de:=-de;
                  diff:=ih-th+de;
                  writeln(file2,fp:3,'-',pt:3,'  Diff. El.=',diff:7:3,'  dEl:',de:7:3);
                  writeln(fp:3,'-',pt:3,'  Diff. El.=',diff:7:3,'  dEl:',de:7:3);
                  if pt=t_pt then
                    begin
                      p1_reg:=fp;
                      p2_reg:=pt;
                      el_reg:=diff;
                    end;
                end
              else setup:=false;
              if pt>999 then pt:=pt-(1000-control_pt);
                hz_ang:=ha*pi/180;
              vert_ang:=va*pi/180;
              distance:=sd*sin(vert_ang);
              f_dist:=-sd;
              rod:=th;
              descrip:=des2;
              if pt>no_pts+1 then for j:=no_pts+1 to pt-1 do put(j,pt_rec2);
              put(pt,pt_rec);
              if pt>no_pts then no_pts:=pt;
            end;
        until (pt=0) or (eof(sdr_file));
    end;
  pt_rec0.from_pt:=no_pts;
  put(0,pt_rec0);
  close(pt_file);
  close(sdr_file);
end;

procedure tranform;
 type str60 = string[60];

  var
    file1 : text;
    file2 : file of str60;
    file3 : text; {file of string[70];}
    rec_ln: str60;
    rec_ln2,
    rec_ln3 :string[70];
    rec_ln4 :str60;
    rec_cnt : integer;
    tv02    : array[1..400] of integer;
    tv12    : array[1..400] of integer;
    nm03    : array[1..400] of integer;
    tp02    : array[1..400,1..2] of integer;
    tv02_cnt,
    tv12_cnt,
    nm03_cnt,
    tp02_cnt : integer;
    p        : string[4];
    p2       : string[12];
    err      : integer;
    tv       : integer;
    obs_cnt  : integer;      { number of observation in a sumary table }
    set_rec     : integer;   { rec counter to find sets of traverse data }
    face1       : boolean;   { use face one data or average by SDR }
    comp_set    : integer;   { complete set }
    bs_shot     : boolean;
    close_set   : boolean;
    i,j         : integer;


  procedure get_tar_rec(j:integer; var rec_ln:str60);
    var l : integer;
    begin
      l:=nm03_cnt+1;  { back search for target height record }
      repeat dec(l); until (nm03[l]<j) or (l=1);
        if (l=1) and (nm03[l]>=j) then
          begin
            rec_ln:='03NM0.000  ';
            writeln(^G,'*** No Target Height Found, 0.000 Substituted ***');
          end
        else begin seek(file2,nm03[l]); read(file2,rec_ln); end;
    end;

  procedure get_topo_data(end_cnt:integer);
    var m : integer;
    begin
      repeat   { get topo data observation, J must be set.}
        inc(j); seek(file2,j); read(file2,rec_ln);
        rec_ln3:=rec_ln;
        if pos(copy(rec_ln,1,4),'02TP07TP')>0 then { new setup in topo mode }
          begin
            m:=1; while tp02[m,1]<>j do m:=m+1;
            tp02[m,2]:=0; { flag that this topo data is done }
            writeln('    Found TOPO Set');
            if close_set then
              writeln(file3,'        0 0       0        0          0          ');
            if copy(rec_ln,1,4)= '02TP' then
              writeln(file3,copy(rec_ln,5,4),' 000 ',copy(rec_ln,36,60))
            else begin
                   m:=j+1;
                   repeat
                     m:=m-1;
                     seek(file2,m); read(file2,rec_ln4);
                   until (copy(rec_ln4,1,8)='02TP'+copy(rec_ln,5,4)) or
                         (copy(rec_ln4,1,8)='02TV'+copy(rec_ln,5,4)) or
                         (copy(rec_ln4,1,8)='02CO'+copy(rec_ln,5,4)) or
                         (m=1);
                   if    (copy(rec_ln4,1,8)='02TP'+copy(rec_ln,5,4)) or
                         (copy(rec_ln4,1,8)='02CO'+copy(rec_ln,5,4)) or
                         (copy(rec_ln4,1,8)='02TV'+copy(rec_ln,5,4)) then
                     writeln(file3,copy(rec_ln,5,4),' 000 ',copy(rec_ln4,36,60))
                   else
                     begin
                       writeln(^G,'*** No Setup Data Found,  HI=5.00'' Substituted ***');
                       writeln(file3,copy(rec_ln,5,4),' 000    5.000     NO Trav.Setup');
                     end;
                 end;
            bs_shot:=false;
          end;
        if copy(rec_ln,1,4)='09F1' then
          if (copy(rec_ln,9,1)='1') or (not bs_shot) then { topo starts at 1000 }
            begin
              bs_shot:=true;
              get_tar_rec(j,rec_ln);
              rec_ln3:='     '+copy(rec_ln3,9,4)+' '+copy(rec_ln,5,5)+' '+copy(rec_ln3,13,60);
              writeln(file3,rec_ln3);
            end;
      until (eof(file2)) or (j>=end_cnt);
      writeln(file3,'        0 0       0        0          0          ');
    end;

begin
   for i:=1 to 400 do
     begin
       tv02[i]:=30000;    { Set up Point }
       tv12[i]:=30000;    { Start of summary table }
       nm03[i]:=-1;       { target Height }
       tp02[i,1]:=30000;  { Topo Setups }
       tp02[i,2]:=1;      { 0 if topo data block has been calculated }
     end;
   tv02_cnt:=0;
   tv12_cnt:=0;
   nm03_cnt:=0;
   tp02_cnt:=0;
   rec_cnt:=0;
   writeln('****  TranForm SDR -  Ver. 8711.09  ****');
   writeln('Converts SDR2 Comms Output file to Intermidiate file.');

   path:=''; fn:=read_fn('*.SDR',13,8,'SDR',true);

   i:=pos('.',fn); if i>0 then fn:=copy(fn,1,i-1);
   if not exist(fn+'.SDR') then
     begin
       writeln;
       cnff(fn+'.SDR');
       exit;
     end;
   assign(file1,fn+'.SDR'); reset(file1);
   assign(file2,fn+'.60'); rewrite(file2);
   while not eof(file1) do
     begin
       readln(file1,rec_ln);
       write(file2,rec_ln);
       if length(rec_ln)>3 then p:=copy(rec_ln,1,4) else p:='';
       if (p= '02TV') or (p='02CO') then
         begin inc(tv02_cnt); tv02[tv02_cnt]:=rec_cnt; end
       else if p= '12TV' then
              begin inc(tv12_cnt); tv12[tv12_cnt]:=rec_cnt; end
            else if p= '03NM' then
                   begin inc(nm03_cnt); nm03[nm03_cnt]:=rec_cnt; end
                 else if (p='02TP') or (p='07TP') then
                        begin inc(tp02_cnt); tp02[tp02_cnt,1]:=rec_cnt; end;
       rec_cnt:=rec_cnt+1;
     end;
   nm03[nm03_cnt+1]:=rec_cnt;  { records start at 0 }
   close(file1);
   assign(file3,fn+'.70'); rewrite(file3);

   writeln('Use  SDR Average Adjusted Traverse Data or');
   write('     Face 1 Raw Observation Data   (A/F) ');
   quest(0,0,'  ? ',['A','F'],false); writeln;
   if response='A' then face1:=false else face1:=true;
   writeln;

   comp_set:=0;
   close_set:=true; { to put zero line to end group setup }
   for i:=1 to tv02_cnt do { # of setups If no setup do nothing }
     begin
       writeln('+++ Working on SETUP Group #',i:3,' +++');
       set_rec:=1;
       repeat
         tv:=-1; { summary flag }
         while (set_rec<=tv12_cnt) and (tv=-1) do { multiable set per setup }
           begin if (tv12[set_rec]<tv02[i+1]) and
                    (tv12[set_rec]>tv02[i]) then tv:=tv12[set_rec];
             set_rec:=set_rec+1;
           end;
         if tv>0 then { yes we have a summary }
           begin
             comp_set:=comp_set+1;
             writeln('    Found TRAV Setup #',comp_set:3);
             seek(file2,tv);
             read(file2,rec_ln);  { get setup summary header line }
             rec_ln3:=copy(rec_ln,9,3);
             val(copy(rec_ln,9,3),obs_cnt,err);
             if obs_cnt>0 then { no. of pts shot in traverse mode }
               begin
                 seek(file2,tv02[i]);
                 read(file2,rec_ln);
                 rec_ln2:=copy(rec_ln,5,4)+' '+rec_ln3+' '+copy(rec_ln,36,60);
                 writeln(file3,rec_ln2); { write header of setup }
                 for j:=tv+1 to tv+obs_cnt do  { get observations in summary table }
                   begin
                     seek(file2,j); read(file2,rec_ln); { listing in table }
                     rec_ln3:=rec_ln;
                     p2:=copy(rec_ln,1,12);  { FROM-TO pt # }
                     k:=tv;
                     if face1 then
                       begin
                         repeat      { back search for observation }
                           k:=k-1;
                           seek(file2,k); read(file2,rec_ln);
                           if k=1 then
                             begin
                               writeln;
                               writeln(^G,'*** ERROR *** Can not find F1 Shot - SDR record=',j:4);
                               writeln('    Insert Correct F1 SDR Record @ Line',tv-1:4);
                               writeln('    or Try Using Average Adjusted Data Option');
                               writeln(' ==>NOW Substituting <ZERO> Record for Missing F1 Shot');
                               writeln(' ==>You Should Fix the Incorrect Pt. in the Pt. File.');
                               writeln;
                               quest(0,0,'...Pesss <SPACE BAR> to Continue TRANFORMATION',[' '],false);
                               writeln;
                               writeln;
                               rec_ln:='09F1'+copy(p2,5,8)+
                                       '0.000     90.00000  000.00000'+
                                       ' F1?-Error'+copy(rec_ln3,42,9);
                             end;
                         until (((copy(p2,5,8)=copy(rec_ln,5,8)) and
                               (copy(rec_ln,1,4)='09F1'))) or (k=1);
                         rec_ln3:=rec_ln;  (* delete line for adjusted data *)
                       end;
                     get_tar_rec(k,rec_ln);
                     rec_ln3:='     '+copy(rec_ln3,9,4)+' '+copy(rec_ln,5,5)+' '+copy(rec_ln3,13,60);
                     writeln(file3,rec_ln3);
                   end{for j};
                 bs_shot:=true;
                 get_topo_data(tv02[i+1]);
               end{if obs_cnt>0};
           end{if tv>0}
         else
           begin
             seek(file2,tv02[i]); read(file2,rec_ln);
             rec_ln3:='000';
             rec_ln2:=copy(rec_ln,5,4)+' '+rec_ln3+' '+copy(rec_ln,36,60);
             writeln(file3,rec_ln2);
             bs_shot:=false;
             j:=tv02[i]; get_topo_data(tv02[i+1]);
           end;
       until (tv12[set_rec]>tv02[i+1]) or (set_rec>tv12_cnt);
     end{for i:=1 to tv02_cnt};

   writeln;
   writeln('+++ Checking for LONE Topo Shots ++++');
   close_set:=false;
   for i:=1 to tp02_cnt do if tp02[i,2]=1 then
     begin
       bs_shot:=false;
       j:=tp02[i,1]-1; get_topo_data(tp02[i+1,1]-1);
     end;

   writeln('==========================================');
   quest(0,0,'...Pesss <SPACE BAR> to Continue',[' '],false); writeln;
   writeln;

   close(file2);
   erase(file2);
   reset(file3);
   while not eof(file3) do
     begin
       readln(file3,rec_ln3);
       writeln(rec_ln3);
     end;
   close(file3);
end;

procedure spool_coor;
  begin
{$if 1=0}
    if not c_ptr[plt_port].active then
      begin
        writeln;
        set_com(plt_port,com_set_rec_no);
        writeln;
        path:=''; fn:=read_fn('*.COD',13,8,'COor. Download',true);
        i:=pos('.',fn); if i>0 then fn:=copy(fn,1,i-1);
        flush_pt_file; try_plot(fn+'.COD');
      end
    else begin
           writeln(^G,'A drawing is being Plotted.');
           writeln('To send Coordinate data, you must first [P]urge the port.');
         end;
{$endif}
  end;

begin
  fn:='';
  repeat
    mode('Convert SDR2 Comms Output File');
    gotoxy(1,3);
    menu_entry('Transform SDR file to Intermediate (.70) File',1);
    menu_entry('Convert Intermediate File to PC-TS Pt File.',1);
    menu_entry('Make Down Loadable SDR-2 Coordinate Data File.',1);
    menu_entry('Spool Coordinate File to SDR-2 via Plotter Port.',1);
    writeln;
    menu_entry('Exit.',1);
    menu_op(['T','C','E','M','S']);
    gotoxy(1,9);
    case response of
      'T':tranform;
      'C':sdr_pt;
      'M':co_down;
      'S':spool_coor;
    end{case};
  if response<>'E' then begin
      writeln; quest(0,0,'...Press <SPACE BAR> to Continue',[' '],false);
  end;
  until response='E';
  gotoxy(1,17);
  writeln('Use   "GP - Get Points"  option to append the SDR2 point data');
end;
{$ENDIF}

end.
