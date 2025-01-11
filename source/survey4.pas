{$F+,O+}
unit survey4;
interface
uses crt,survey0,basics2;

procedure ang_math;
procedure protect(ver:integer);
procedure get_pt;

implementation

procedure ang_math;
 var
   sum,a : real;
   asz1  : str16;
   cnt360:integer;

 begin
   mode('Angle Math'); write(' Use  +  -  =  [I]nverse (360-A)');
   if lst_flag then writeln(lst,'Angle Math');
   gotoxy(1,3);
   response:='+';
   sum:=0;
   cnt360:=0;
   repeat
     a:=0;
     if response<>'I' then
       begin
         write('Enter Angle ? '); input_asz(asz1);
         if asz1<>'' then a:=asz_rad(asz1)
         else begin
                gotoxy(1,wherey); clreol;
                write('Enter Bearing ? '); input_bear(asz1);
                if asz1<>'' then a:=bear_rad(asz1);
              end;
       end;
     case response of
        '+':sum:=sum+a;
        '-':sum:=sum-a;
        'I':sum:=2*pi-sum;
     end{case};
     while sum<0 do sum:=sum+2*pi;
     roll_asz(rad_asz(sum));
     gotoxy(1,wherey); clreol;
     write(rad_asz(a),'    ',rad_bear(a));
     textcolor(yellow); write('  Sum=',rad_asz(sum));
     textcolor(white);
     quest(0,0,'  + - =  ?  ',['+','-','=','I'],false); writeln;
     if lst_flag then
       writeln(lst,'  ',rad_asz(a),'    ',rad_bear(a),'  Sum=',rad_asz(sum),' ',response);
   until response='=';
 end;

procedure protect(ver:integer);
  var
   el,eh,nl,nh: real;
    i,p1,p2 : integer;
    pt_rec  : point;
    ver_des : string[3];
    ver_des2: string[12];
begin
   el:=10e10; nl:=el;
   nh:=-10e10; eh:=nh;
   ver_des:=''; if ver in [2,4] then ver_des:='UN-';
   ver_des2:=' Coordinates';if ver in [3,4] then ver_des2:=' Elevations';
   if ver=5 then mode('Find Max.-Min. Coordinates Limits')
   else mode(ver_des+'Protect'+ver_des2);
   write('   START Pt# ? '); p1:=9999; input_i(p1);
   write('   END Pt# ? ');   p2:=9999; input_i(p2);
   if (p2>=p1) and (p2<=no_pts) and (p1<=no_pts) then
     begin
       if ver in [1,3] then
         quest(1,3,'PERMANATELY Protect'+ver_des2+' (Y/N) ? ',['Y','N'],false);
       gotoxy(1,5);
       if ver=5 then write('     Pts. Checked')
       else write('      Pts ',ver_des,'Protected');
       for i:=p1 to p2 do with pt_rec do
         begin
           write(^M,i:4);
           get(i,pt_rec);
           case ver of
             1:if response='Y' then from_pt:=0 else from_pt:=-abs(from_pt);
             2:from_pt:=abs(from_pt);
             3:if response='Y' then rod:=0 else rod:=-abs(rod);
             4:rod:=abs(rod);
             5:if (east>0) or (north>0) then
                 begin
                   el:=min(el,east);
                   nl:=min(nl,north);
                   eh:=max(eh,east);
                   nh:=max(nh,north);
                 end;
           end{case};
           if ver<>5 then put(i,pt_rec);
         end;
       if ver=5 then
         begin
           gotoxy(1,7);
           writeln('North Low =',nl:9:2,'  East Low =',el:9:2);
           writeln('North High=',nh:9:2,'  East High=',eh:9:2);
         end;
     end;
end;

procedure get_pt;
var
  fn         : string[30];
  app_file   : file of point;
  pt_rec     : point;
  no_app_pts : integer;
  no_pts2    : integer;
  p1,p2,i    : integer;

begin
  mode('Append Pts from Another File');

  path:=''; fn:=read_fn('*.pt',13,8,'  Point',true); writeln;

  i:=pos('.',fn); if i>0 then fn:=copy(fn,1,i-1);
  fn:=fn+'.PT';
  if exist(fn) then
    begin
      assign(app_file,fn); reset(app_file);
      seek(app_file,0); read(app_file,pt_rec);
      no_app_pts:=pt_rec.from_pt;
      writeln('There are ',no_app_pts:4,' pts. in file #2.');
      writeln;
      write('Enter Starting Pt#=1 ? '); p1:=1; input_i(p1); writeln;
      write('Enter  Ending  Pt#=',no_app_pts:4,' ? ');
      p2:=no_app_pts; input_i(p2); writeln;
      writeln;
      write('      Points Appended');
      if (p1<=no_app_pts) and (p2<=no_app_pts) and (p2>=p1) then  begin
        init_pt_rec(pt_rec); pt_rec.descrip:='GET-PT: '+fn; put(no_pts+1,pt_rec);
        no_pts2:=no_pts;
        for i:=p1 to p2 do with pt_rec do
          begin
            seek(app_file,i); read(app_file,pt_rec);
            if (from_pt>=p1) and (from_pt<=p2) and
               (bs_pt<from_pt) and ((bs_pt>=p1) or (bs_pt=0)) then
               begin from_pt:=no_pts2+from_pt-p1+1;
                     if bs_pt>0 then bs_pt:=no_pts2+bs_pt-p1+1 else bs_pt:=0;
               end
            else begin from_pt:=0; bs_pt:=0; end;
            rod:=pt_rec.rod;
            put(no_pts+1,pt_rec);
            write(^M,i:4);
          end;
        if lst_flag then
          writeln(lst,'GET POINTS from file: ',fn,
                      '  Pt# ',p1,'-',p2,'  Append @ Pt# ',no_pts-p2+p1-1);
      end
      else writeln(^G,'*** No pts Appended ***');
      close(app_file);
    end
  else cnff(fn);
end;

end.
