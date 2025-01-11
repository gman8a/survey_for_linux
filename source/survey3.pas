unit survey3;
interface
uses dos,crt,survey0,basics2,survey13;

procedure stake;
procedure print_pt_data;
procedure Tog_printer;
procedure no_pts_grab;

implementation

procedure Tog_printer;
   begin
      close(lst);
      mode('TOggle Printed Output');

      quest(1,5,'Print Data ? [Y]es  [N]o ? ',['Y','N'],false);
      lst_flag:=(response='Y');
      if lst_flag then
        begin
          quest(1,7,'Direct data to ?  [P]rinter  [F]ile: '+copy(fn,1,pos('.',fn))+'LST ? ',['P','F'],false);
          if response='P' then assign(lst,'PRN')
          else
            begin assign(lst,lst_fn); if not exist(lst_fn) then rewrite(lst); end;
        end;
      append(lst);
      tag_prn(fn+': '+pt_rec0.descrip);
    end;

procedure no_pts_grab;
  begin
    mode('Quick Point Delete or Grab Back'); gotoxy(1,15);
    if alt_flag then nj:=filesize(alt_pt_file) else nj:=filesize(pt_file);
    writeln('Total No. Records in File = ',nj-1:4);
    writeln; write('Pt. Grab feature:  no_pts=',no_pts:4,'  ? '); input_i(i);
    if (i>0) and (i<nj) then set_no_pts(i);
    writeln(' = ',no_pts:4);
  end;

procedure stake;
 var
   bs,sp,y    : integer;
   j          : integer;
   pt_rec     : point;
   asz1,asz2,
   asz3,asz4  : str16;
   d,a1       : real;
   last_pt    : integer;
   thru_pt    : integer;
   thru_flg   : boolean;

 const
    cr =^J^M;  { cr & lf char }

   begin
     mode('LOCATE Pts in Field');
     write(CR,' Setup on Pt# ? ':33);
     sp:=dig_point;
     write(CR,' Back Site (000 Deg.) on  Pt# ? ':33);
     bs:=dig_point;
     if (bs<=no_pts) and (sp<=no_pts) then
       begin
         pt_to_pt(sp,bs,d,asz2);  { get back sight aszmith }
         writeln(cr,cr,'Pt#':4,'HZ-Ang Right':14,'Distance':10,'Bear / Azimuth':17,'Elevation':12,'Description':13);
         writeln(      '===':4,'============':14,'========':10,'==============':17,'=========':12,'===========':13);
         if lst_flag then
           begin
             tag_prn(fn+': '+pt_rec0.descrip);
             writeln(lst,'|-----> Field Stake Out <-----|');
             writeln(lst,'  Setup on Pt#',sp:3);
             writeln(lst,'  Backsite Pt#',bs:3);
             writeln(lst);
             writeln(lst,'Pt#':4,'HZ-Ang Right':14,'Distance':10,'Bear / Azimuth':17,'Elevation':12,'Description':13);
             writeln(lst,'===':4,'============':14,'========':10,'==============':17,'=========':12,'===========':13);
           end;
         y:=wherey;
         j:=bs;
         thru_flg:=false;
         repeat
           last_pt:=j;
           pt_to_pt(sp,j,d,asz1);          { Distance }
           asz4:=asz1;  { azmiuth to pt }
           if not as_br_flg then asz4:=rad_bear(asz_rad(asz4));
           a1:=asz_rad(asz1)-asz_rad(asz2);
           while a1<0 do a1:=a1+2*pi;
           asz3:=rad_asz(a1);              { Hz-ang to pt }
           get(j,pt_rec);
           gotoxy(1,y);
           writeln(j:4,'  ',asz3,d:10:3,' ':3,asz4:14,pt_rec.elev:11:2,'   ',pt_rec.descrip);
           if lst_flag then
             writeln(lst,j:4,'  ',asz3,d:10:3,' ':3,asz4:14,pt_rec.elev:11:2,'   ',pt_rec.descrip);
           y:=wherey;
           gotoxy(30,1); clreol;
           write('Enter Pt# (0 Thru) ? '); j:=9999;
           if not thru_flg then j:=dig_point;
           if j=0 then
             begin
               write('  Thru ? ');
               thru_pt:=0; thru_pt:=dig_point;
               if (thru_pt>last_pt) and (thru_pt<=no_pts) then thru_flg:=true;
               j:=last_pt;
             end;
           if thru_flg then j:=last_pt+1;
           if j=thru_pt then thru_flg:=false;
         until (j>no_pts) or (j<1);
       end;
   end;

procedure print_pt_data;
    var
      p1,p2  : integer;
      pt_rec : point;


  procedure get_range;
    begin
      writeln;
      write('  Enter Start Listing Pt#=1 ? '); p1:=1; input_i(p1); writeln;
      write('  Enter Ending Pt#=',No_pts:3,' ? '); p2:=no_pts; input_i(p2); writeln;
      if p2>no_pts then p2:=no_pts;
      tag_prn(fn+': '+pt_rec0.descrip);
      writeln; write('      Point Coordinates Sent to Printer');
    end;

  procedure list_double;
    begin
      mode('List Coor. Double Column');
      writeln;
      get_range;
      repeat
        get(p1,pt_rec);  write(^M,p1:4);
        with pt_rec do write(lst,p1:4,' ',north:11:4,' ',east:11:4,elev:9:2,descrip:21,'  ');
        if int(p1/2)=p1/2 then writeln(lst);
        inc(p1);
        if p1/121=int(p1/121) then begin write(lst,^L); tag_prn(fn+': '+pt_rec0.descrip); end;
      until (p1>p2);
      writeln;
      writeln(lst,^L);
    end{double};

  procedure list_single;
    var i : integer;

    procedure header;
      begin
        writeln(lst,'PT#  Fr_Pt BS_pt SU    Description        Northing     Easting      Elev.');
        writeln(lst,'==== ===== ===== == ==================== =========== =========== ===========');
      end;

    begin
      mode('List Coor. Single Column'); writeln;
      get_range;
      header;
      for i:=p1 to p2 do
        begin
          get(i,pt_rec); write(^M,i:4);
          with pt_rec do begin
            write(lst,i:4,from_pt:6,bs_pt:6);
            if setup=true then write(lst,'Y':3) else write(lst,'N':3);
            writeln(lst,descrip:21,north:12:3,east:12:3,elev:12:3);
            if i/60=int(i/60) then
              begin write(lst,^L); tag_prn(fn+': '+pt_rec0.descrip); header; end;
          end;
        end;
    end{single};

  procedure print;

    procedure print_rec(pt:integer; pt_rec:point);
      var
        de      : real;  { delta elevation }
        ch      : string[1];
        j       : integer;
        ch2     : string[3];
      begin
        with pt_rec do
          begin
            if (* (rod>0) and *) (vert_ang>0) then
              begin
                de:=tan(abs(vert_ang-pi/2))*distance;
                if vert_ang>pi/2 then de:=-de;
              end
            else de:=0;
            if code<2 then ch:='R' else ch:='L';
            if setup then ch2:='YES' else ch2:='NO ';
            writeln(lst,'Pt#:',pt:3,'  FromPt#:',from_pt:3,'  BSPt#:',bs_pt:3,
                        '  Setup:',ch2,'   Descrip: ',descrip);
            if bs_ang>0 then write(lst,' BS_Ang:  ',rad_asz(bs_ang),' ')
            else write(lst,'=======================');
            for j:=23 to 77 do write(lst,'='); writeln(lst);
            if code=0 then write(lst,'A') else write(lst,'a');
            writeln(lst,'szmith:  ',rad_asz(aszmith),   '  Distance:  ',distance:9:3,
                                   '    Rod: ',rod:5:2,'  North:',north:11:4);
            writeln(lst,'Bearing: ',rad_bear(aszmith),    '  VertAng: ',rad_asz(vert_ang),
                                  '  dEl:',de:6:2,'   East:',east:11:4);
            if code>0 then write(lst,'H') else write(lst,'h');
            write(lst,'orzAng:  ',rad_asz(hz_ang),CH:1,'   F_Dist: ');
            if f_dist>=200000.0 then write(lst,'R',f_dist-200000.0:9:3)
            else if f_dist>=100000.0 then write(lst,'E',f_dist-100000.0:9:3)
                 else if f_dist<0 then write(lst,'P',-f_dist:9:3)
                      else write(lst,'H',f_dist:9:3);
            writeln(lst,'     HI: ',hi:5:2,'   Elev:',elev:11:4);

          end;
      end{print_rec};

    var i : integer;

    begin
      mode('Print Points'); writeln;
      get_range;
      for i:=p1 to p2 do
        if (i<=no_pts) and (i>=1) then
          begin
            get(i,pt_rec);
            display_rec(i,7,lightgray,white,pt_rec);
            print_rec(i,pt_rec);
            writeln(lst);
            if i/10=int(i/10) then write(lst,^L);
          end;
      write(lst,^L);
    end{Print Point Records};

  var f : boolean;

  begin{print_pt_data}
    mode('PRint Point Data'); gotoxy(1,4);
    write('Set Printer Top-of-Form (turn off then on)');
    writeln;
    writeln;
    f:=lst_flag; lst_flag:=true;
    menu_entry('Single column',1);
    menu_entry('Double column',1);
    menu_entry('Point records',1);
    writeln;
    menu_entry('Exit',1);
    menu_op(['S','D','P','E']);
    case response of
      'S':begin prn_set(1); list_single; end;
      'D':begin prn_set(3); list_double; end;
      'P':begin prn_set(1); print; end;
    end{case};
    prn_set(0);
    lst_flag:=f;
  end;


end.
