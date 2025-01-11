unit survey12;
interface

uses crt,survey0,basics2,survey13;

procedure area;
procedure settings;

implementation

procedure settings;
  begin
    mode('PC-TS Settings'); writeln;
    menu_entry('Left',1);                     menu_entry('Right',2);
    menu_entry('Azimuth',1);
    menu_entry('Vertical Angles',1);          menu_entry('Delta Elevations',2);
    menu_entry('Prism or Slope Dist.',1);     menu_entry('EDM',2);
    menu_entry('Horizontal Distance',1);      menu_entry('Stadia or Rod',2);
    menu_entry('Yes Setup Point',1);          menu_entry('No Setup Point',2);
    menu_entry('Bottom Registers On',1);      menu_entry('Invisable Registers',2);

    writeln(' Back-site angle edit:   [O]n   o[F]f');
    writeln;
    writeln('                         e[X]it');

    repeat
      menu_op(['A','R','L','V','D','P','H','S','E','O','F','Y','N','X','I','B']);
      case response of
        'A':pt_rec0.code:=0;
        'R':pt_rec0.code:=1;
        'L':pt_rec0.code:=2;
        'O':bs_edit:=true;
        'F':bs_edit:=false;
        'V':vert_type:='V';
        'D':vert_type:='D';
        'P':last_dist_type:='P';
        'H':last_dist_type:='H';
        'S':last_dist_type:='R';
        'E':last_dist_type:='E';
        'Y':pt_rec0.setup:=true;
        'N':pt_rec0.setup:=false;
        'I':begin reg_disp_flg:=false; des_disp_flg:=false; end;
        'B':begin reg_disp_flg:=true; des_disp_flg:=true; end;
      end{case};
      if response in ['P','H','S','E'] then dist_type:=' ';
    until response='X';
  end;

procedure  Area1;
  var
    i,j,k,l   : integer;
    p         : array[1..200,1..2] of real;
    area,b    : real;
    pt_rec    : point;
    cir_cnt   : integer;
    asz1,asz2 : str16;
    d1,d2     : real;
    delta,s,t : real;
    p1,p2     : integer;
    cen_pt    : integer;
    area2     : real;
    cen_cnt   : integer;
    lc,cc     : integer;
    mult_ln_flg:boolean;
    mult_cnt : integer;
    mult_ln_end : integer;
    area_file   : text;
    afn         : string;
    lot         : integer;
  const
    rad_acc   =0.00001; { radian accuarcy }

  begin
        mode('Area Calculation');
        afn:=copy(fn3,1,length(fn3)-2)+'ARZ'; assign(area_file,afn);
        if exist(afn) then append(area_file) else rewrite(area_file);
        write('  Stack File: ',afn,'  Enter Lot No. ? '); lot:=0; input_i(lot);
        str(lot:4,afn); for i:=1 to 4 do if afn[i]=' ' then afn[i]:='0';
        write(area_file,afn);
        lc:=9;
        gotoxy(18,1); write('  Enter Pt# ? (- Center Pt#,  +/- P.T. Pt#,  0 Thru)');
        area:=0; area2:=0; p1:=0;
        j:=0; cir_cnt:=0;
        cen_cnt:=0;
        cc:=1;
        mult_ln_flg:=false;
        if lst_flag then writeln(lst,'Area Calculation');
        repeat
          j:=j+1;
          repeat
            gotoxy(5,15); clreol; textcolor(white);
            write('Enter Pt#',j:2,' ? ');
            men_but:=0;
            if not mult_ln_flg then k:=dig_point;
            if k=0 then
              begin write('  To Pt# ? ');
                    mult_ln_end:=dig_point; write('   '); write(area_file,k:6);
                    mult_ln_flg:=true;
              end;
            if mult_ln_flg then
              begin
                if mult_ln_end>mult_cnt then k:=mult_cnt+1
                else k:=mult_cnt-1;
                write(k);
                if k=mult_ln_end then mult_ln_flg:=false;
              end;
            if men_but=255 then k:=-k; (*** for digitizer ***)
            mult_cnt:=abs(k);
            gotoxy(1,19); clreos;
            if j=1 then l:=k;
            if abs(k)>no_pts then begin bad_pt_msg; delay(1500); end
            else if not mult_ln_flg then write(area_file,k:6);
            if (k>0) and (k<=no_pts) and (cir_cnt=0) and (p1<>0) then
                begin
                  pt_to_pt(abs(p1),k,d1,asz1);
                  if not as_br_flg then asz1:=rad_bear(asz_rad(asz1));
                  if lst_flag then writeln(lst,p1:7,k:5,' Line  ',asz1,d1:10:4);
                  gotoxy(1,20);
                  writeln(p1:7,k:5,' Line  ',asz1,d1:10:4);
                end;
          until abs(k)<=no_pts;
          if (k<0) and (cir_cnt=0) then cir_cnt:=1;
          case cir_cnt of
            0:p1:=k;
            1:begin cen_pt:=abs(k); cir_cnt:=2; end;
            2:begin p2:=k; cir_cnt:=3; end;
          end{case};
          get(abs(k),pt_rec);
          display_rec(k,3,lightgray,white,pt_rec);
          if (j+cen_cnt) mod 11=1 then
            begin inc(lc);
                  if lc>10 then
                    begin writeln(area_file); write(area_file,' ':4); end;
            end;
          gotoxy(cc,lc);
          cc:=cc+6; if cc=67 then cc:=1;
          textcolor(white); write(k:4);
          if cir_cnt<>2 then
            begin
              p[j,1]:=pt_rec.north;
              p[j,2]:=pt_rec.east;
            end
          else begin dec(j); inc(cen_cnt); end;
          if cir_cnt=3 then
            begin
              pt_to_pt(cen_pt,p1,d1,asz1);        { d1=radius}
              pt_to_pt(cen_pt,abs(p2),d2,asz2);
              if abs(d1-d2)>0.005 then
                begin
                  if lst_flag then
                    writeln(lst,'*** Error - Radii not Equal ***  Rad1-Rad2=',d1-d2:10:5);
                  gotoxy(1,19);
                  writeln(^G,'*** Error - Radii not Equal ***  Rad1-Rad2=',d1-d2:10:5);
                end;
              delta:=asz_rad(asz2)-asz_rad(asz1);
              while delta<0 do delta:=delta+2*pi;
              if delta>pi then delta:=2*pi-delta; { Minor Arc only }
              area2:=area2+sqr(d1)*(delta/2-sin(delta/2)*cos(delta/2))*(p2/abs(p2));
              pt_to_pt(p1,abs(p2),d2,asz2);       { chord length }
              if not as_br_flg then
                asz2:=rad_bear(asz_rad(asz2));      { chord bearing }
              s:=delta*d1;                        { curve length }
              asz1:=rad_asz(delta);               { delta angle }
              if (abs(delta-pi/2)>rad_acc) and (abs(delta-pi)>rad_acc)
              then t:=tan(delta/2)*d1 else t:=d1;{d1=radius}
              gotoxy(1,20);
              writeln(p1:7,p2:5,' Chord ',asz2,d2:10:4);
              writeln('Cen.Pt#':11,cen_pt:4,' Del=',asz1,' Len=',s:10:4,' Rad=',d1:10:4,' Tan=',t:10:4);
              if lst_flag then
                begin
                  writeln(lst,p1:7,p2:5,' Chord ',asz2,d2:10:4);
                  writeln(lst,'Cen.Pt#':11,cen_pt:4,' Del=',asz1,' Len=',s:10:4,' Rad=',d1:10:4,' Tan=',t:10:4);
                end;
              p1:=abs(p2);                        { for P.R.C. }
              cir_cnt:=0;
            end;
        until (abs(k)=abs(l)) and (j>1);
        for i:=1 to j-1 do
          begin
            if i=1 then b:=p[j-1,2] else b:=p[i-1,2];
            area:=area+p[i,1]*(b-p[i+1,2]);
          end;
        area:=abs(area/2)+area2;
        gotoxy(5,15); clreol;
        textcolor(white);
        writeln('Area =',area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres');
        if lst_flag then
           begin
             writeln(lst,' Area =':8,area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres');
             writeln(lst);
             writeln(lst);
           end;
    writeln(area_file,'   LOT #',lot);
    close(area_file);
  end;

procedure  Area2;
  var
    i,j,k,l   : integer;
    p         : array[1..250,1..2] of real;
    area,b    : real;
    pt_rec    : point;
    cir_cnt   : integer;
    asz1,asz2 :str16;
    d1,d2     : real;
    delta,s   : real;
    p1,p2     : integer;
    cen_pt    : integer;
    area2     : real;
    lot_file  : text;
    lot       : integer;
    t         : real; { tangent of 1/2 delta * radius }
    mult_ln_end : integer;
    mult_cnt    : integer;
    mult_ln_flg : boolean;
    area_acc    : real;
    lot2        : integer;
    lot_des     : string[40];

  const
    rad_acc   =0.00001;

  begin
    mode('Compute Lot Areas using File Input');
    writeln('  ...Ready Your Printer.');
    lot_des:=get_dir(fn5+'?',false);
    writeln;
    write('Last character of Area Work File: ',fn5);
    quest(0,0,' ? ',[' ','0'..'9','A'..'Z','a'..'z'],false); writeln;
    write('Output data for Lot # ?  <RETURN>=All ? '); lot2:=0; input_i(lot2);
    writeln; writeln; clreos;
    if exist(fn5+response) then
      begin
        assign(lot_file,fn5+response); reset(lot_file);
        tag_prn(fn+': '+pt_rec0.descrip);
        mult_ln_flg:=false;
        area_acc:=0;
        while not eof(lot_file) do
          begin
            area:=0; area2:=0; j:=0;  cir_cnt:=0; p1:=0;
            repeat
              read(lot_file,lot);
              if (lot2<>0) and (lot<>lot2) then readln(lot_file);
            until (abs(lot2)=abs(lot)) or (lot2=0) or eof(lot_file);
            if eof(lot_file) then
              begin close(lot_file);
                    writeln(^G,'****  Can NOT find LOT #',lot2,'  ****'); exit;
              end;
            write('Lot#',lot:4,' ==> ');
            if lst_flag then writeln(lst,'*** LOT #',lot:3,' ***');
            repeat
              j:=j+1;
              if not mult_ln_flg then read(lot_file,k);
              if k=0 then
                begin read(lot_file,mult_ln_end); mult_ln_flg:=true; end;
              if mult_ln_flg then
                begin
                  if mult_ln_end>mult_cnt then k:=mult_cnt+1
                  else k:=mult_cnt-1;
                  if k=mult_ln_end then mult_ln_flg:=false;
                end;
              mult_cnt:=abs(k);
              write(k:5);
              if j=1 then l:=k;
              if abs(k)>no_pts then begin if lst_flag then writeln(lst,'*** Bad Pt# ***'); k:=l; end;
              if (k>0) and (cir_cnt=0) and (p1<>0) then
                begin
                  pt_to_pt(abs(p1),k,d1,asz1);
                  if not as_br_flg then asz1:=rad_bear(asz_rad(asz1));
                  if lst_flag then writeln(lst,p1:7,k:5,' Line  ',asz1,d1:10:4);
                end;
              if (k<0) and (cir_cnt=0) then cir_cnt:=1;
              case cir_cnt of
                0:p1:=k;
                1:begin cen_pt:=abs(k); cir_cnt:=2; end;
                2:begin p2:=k; cir_cnt:=3; end;
              end{case};
              if cir_cnt<>2 then
                begin
                  get(abs(k),pt_rec);
                  p[j,1]:=pt_rec.north;
                  p[j,2]:=pt_rec.east;
                end
              else j:=j-1;
              if cir_cnt=3 then
                begin
                  pt_to_pt(cen_pt,p1,d1,asz1);        { d1=radius}
                  pt_to_pt(cen_pt,abs(p2),d2,asz2);
                  if abs(d1-d2)>0.005 then
                    begin
                      if lst_flag then
                        writeln(lst,'+++ Error - Radii not Equal +++  Rad1-Rad2=',d1-d2:10:5);
                      writeln(^G,' +++ Error - Radii not Equal +++  Rad1-Rad2=',d1-d2:10:5);
                    end;
                  delta:=asz_rad(asz2)-asz_rad(asz1);
                  while delta<0 do delta:=delta+2*pi;
                  if delta>pi then delta:=2*pi-delta; { Minor Arc only }
                  area2:=area2+sqr(d1)*(delta/2-sin(delta/2)*cos(delta/2))*(p2/abs(p2));
                  pt_to_pt(p1,abs(p2),d2,asz2);       { chord length }
                  if not as_br_flg then
                    asz2:=rad_bear(asz_rad(asz2));      { chord bearing }
                  s:=delta*d1;                        { curve length }
                  asz1:=rad_asz(delta);               { delta angle }
                  if (abs(delta-pi/2)>rad_acc) and (abs(delta-pi)>rad_acc)
                    then t:=tan(delta/2)*d1 else t:=d1;{d1=radius}
                  if lst_flag then
                    begin
                      writeln(lst,p1:7,p2:5,' Chord ',asz2,d2:10:4);
                      writeln(lst,'Cen.Pt#':11,cen_pt:4,' Del=',asz1,' Len=',s:10:4,' Rad=',d1:10:4,' Tan=',t:10:4);
                    end;
                  p1:=abs(p2);                        { for P.R.C. }
                  cir_cnt:=0;
                end;
            until (abs(k)=abs(l)) and (j>1);
            readln(lot_file,lot_des); writeln;
            while (length(lot_des)>0) and (lot_des[1]=' ') do delete(lot_des,1,1);
            lot_des:=' ===> '+lot_des;
            for i:=1 to j-1 do
              begin
                if i=1 then b:=p[j-1,2] else b:=p[i-1,2];
                area:=area+p[i,1]*(b-p[i+1,2]);
              end;
            area:=abs(area/2)+area2;
            area_acc:=area_acc+area;
            writeln('Area =':8,area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres  ',lot_des);
            if lot2<>0 then roll_real(area);
            writeln;
            if lot<0 then
               writeln('Area Accum.=',area_acc:11:2,' Sq. ft.  =',area_acc/43560.0:9:4,' Acres');
            if lst_flag then
              begin
                writeln(lst,' Area =':8,area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres  ',lot_des);
                writeln(lst);
                writeln(lst);
                if lot<0 then
                  begin
                    writeln(lst,'Area Accum.=',area_acc:11:2,' Sq. ft.  =',area_acc/43560.0:9:4,' Acres');
                    writeln(lst);
                    area_acc:=0;
                  end;
              end;
            if lot2<>0 then while not eof(lot_file) do readln(lot_file);
          end{while not eof};
        close(lot_file);
      end{if exist}
    else cnff(fn5+response);
    quest(0,0,press,[' '..'~'],false);
  end;

procedure area3;  { Use digitizer to get areas }
  var i,j,k  : integer;
      p      : array[1..200,1..2] of real;
      area,b : real;
      asz    : str16;
      d      : real;
      fp     : integer;

  begin
    mode('Area using Digitizer'); writeln('  Use Digitizer Key Pad for All Entry');
    writeln('1/Snap  2/Chk Snap  3/No Snap  9/Re-Digitize  */Close  #/End ');
    if lst_flag then writeln(lst,'Digitizer Area Calc.');
    j:=0;
    repeat
      repeat
        j:=j+1;
        write(j:2,' ?');
        men_but:=0;
        get_xy(p[j,1],p[j,2]);
        if j=1 then fp:=pt_found;
        if (last_but=9) or (men_but=9) then  { re-digitize }
          begin
            msg(45,'Re-Digitize');
            j:=j-1;
            p[j,1]:=p[j+1,1];
            p[j,2]:=p[j+1,2];
            gotoxy(1,wherey-1); write(j:2,' ?');
          end
        else { close area }
          if (last_but in [10,11]) or (men_but in [10,11]) then
            begin
              p[j,1]:=p[1,1];
              p[j,2]:=p[1,2];
              pt_found:=fp;
            end;
        write(^H,pt_found:4,p[j,2]:9:1,p[j,1]:9:1);
        if j>1 then
          begin
            ptpt(p[j-1,1],p[j-1,2],p[j,1],p[j,2],d,asz);
            writeln(d:10:3,'   ',asz,'  ',rad_bear(asz_rad(asz)));
            if lst_flag then
              writeln(lst,d:10:3,'   ',asz,'  ',rad_bear(asz_rad(asz)));
          end
        else writeln;
      until (last_but in [10,11]) or (men_but in [10,11]);
      area:=0;
      for i:=1 to j-1 do
        begin
          if i=1 then b:=p[j-1,2] else b:=p[i-1,2];
          area:=area+p[i,1]*(b-p[i+1,2]);
        end;
      area:=abs(area/2);
      writeln(^G,'Area =',area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres');
      if lst_flag then begin
        writeln(lst,'Area =',area:10:2,' Sq. ft.  =',area/43560.0:9:4,' Acres');
        writeln(lst); end;
      if (last_but<>11) and (men_but<>11) then
        begin
          write('Keep Pts #1 to ## (Key 00-99) ?');
          repeat write(' '); i:=dig_num; until i in [0..99];
          writeln;
          k:=j;
          if i>j-1 then j:=j-1 else j:=i;
          if (i=0) or (wherey-(k-j+2)<1) then gotoxy(1,1)
          else gotoxy(1,wherey-(k-j+2));
        end;
      clreos;
    until (last_but=11) or (men_but=11) ;
  end;

procedure area;
  begin
    mode('Area Calculations');
    gotoxy(1,4);
    menu_entry('Keyboard Pt Entry.',1);
    menu_entry('File, Get input from ARea file.',1);
    menu_entry('Digitize points.',1);
    writeln;
    menu_entry('Exit',1);
    menu_op(['K','F','D','E']);
    case response of
      'K':area1;
      'F':area2;
      'D':begin if not dig_flag then set_dig; set_menu(99,'CAD'); area3; end;
    end{case};
  end;

end.

