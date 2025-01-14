program sort5;
uses crt,dos;
type
    point = record
              from_pt   : integer;    { pt.#0 if enter N,E }
                bs_pt   : integer;    { back sight pt# to turn hz_ang from zero }
              code      : integer;    { 0-asz/bear, 1-hz_ang/right 2-hz_ang/left }
              descrip   : string[20];
              Setup     : boolean;    { TRUE if this is a setup pt. }
              aszmith   : real;       { In radian measure }
              hz_ang    : real;       { horizontal angle }
              bs_ang    : real;       { Back Sight Angle }
              f_dist    : real;
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
                  x,y:real;
                  el :real;
                  p:integer;
                end;

     alt_pt    = record
                    alt_x : real;
                    alt_y : real;
                    alt_z : real;
                    alt_d : string[20];
                 end;

      str50 = string[50];

  var
    no_pts    : integer;
    pt_file   : file of point;   { file of survey data points }
    sort_file : file of sort_xyp;
    fn,fn8    : string[30];
    pt_rec    : point;
    pt_rec0   : point;
    file_flag : boolean;
    c         : array[0..3200] of ^sort_xyp;   { 3200 max, Easting coordinates }
    i         : integer;
    last_drv  : char;
    ok        : boolean;
   screen     : array[0..2047] of integer absolute $B800:0000;
   s          : string[20];
   ii         : integer;
   alt_pt_rec0  : alt_pt;
   alt_pt_rec   : alt_pt;
   alt_pt_file  : file of alt_pt;
   alt_flag     : boolean;

function lastdisk:char;
  var  regs   : Registers;
       log_drv: integer;
       last_drv:integer;
  begin
    regs.AX:=$1900; MSDos(Regs); log_drv:=lo(regs.ax); { get logged drive }
    last_drv:=0;
    repeat
      inc(last_drv);
      regs.AX:=$0E00; regs.DX:=last_drv; MSDos(Regs);  { Set Drive }
      regs.AX:=$1900; MSDos(Regs);                     { Get default drive }
    until  lo(regs.AX)<>last_drv;
    regs.AX:=$0E00; regs.DX:=log_drv; MSDos(Regs);  { ReSet Logged Drive }
    lastdisk:=chr(last_drv+64);
  end;

procedure Open_Pt_File;
  var
    i  : integer;
  begin
    alt_flag:=false;
    if paramCount>0 then fn:=paramStr(1) else fn:='';
    write(^G,'Coordinate file name: ');
    writeln(fn);
    while copy(fn,1,1)=' ' do delete(fn,1,1);
    for i:=1 to length(fn) do fn[i]:=upcase(fn[i]);
    if length(fn)>0 then
      begin
        i:=length(fn)+1;
        repeat i:=i-1; until (i=0) or (fn[i]='.');
        if i>1 then if fn[i-1]='.' then i:=0;
        if i>0 then
          begin if length(fn)>=i+1 then
                  if copy(fn,i+1,1)='A' then alt_flag:=true;
                fn:=copy(fn,1,i-1);
          end;
        fn8:=fn+'.SRT';
        if fn[2]<>':' then fn8:=last_drv+':'+fn8
        else fn8[1]:=last_drv;
        { parse path out of fn7 }
        i:=length(fn8); repeat i:=i-1; until (i=0) or (fn8[i]='\');
        if i>0 then delete(fn8,3,i-2);
        if alt_flag then
          begin fn :=fn+'.PA'; assign(alt_pt_file,fn);
               {$I-}  reset(alt_pt_file);  {$I+} end
        else begin fn :=fn+'.PT'; assign(pt_file,fn);
             {$I-}  reset(pt_file);  {$I+} end;
        if IOresult=0 then
          begin
            if alt_flag then write('Alternate ');
            writeln('==> Existing Point File Opened'); writeln;
            if alt_flag then
              begin
                read(alt_pt_file,alt_pt_rec0);
                writeln('File Description : ',alt_pt_rec0.alt_d);
                no_pts:=round(alt_pt_rec0.alt_x);
              end
            else
              begin
                read(pt_file,pt_rec0);
                writeln('File Description : ',pt_rec0.descrip);
                no_pts:=pt_rec0.from_pt;
              end;
            file_flag:=true;
          end
        else begin
               writeln('*** Error - Can not Find File ***');
               file_flag:=false;
             end;
        if file_flag then writeln(' Number of Points =',no_pts:4);
      end;
  end;

  procedure quicksort(Lo,Hi: integer);

      procedure sort(l,r: integer);
      var
        i,j : integer;
        x   : real;
      begin
        i:=l; j:=r;
        x:=c[(l+r) div 2]^.x;
        repeat
          while c[i]^.x<x do inc(i);
          while x<c[j]^.x do dec(j);;
          if i<=j then
            begin c[0]:=c[i]; c[i]:=c[j]; c[j]:=c[0];
                  inc(i); dec(j);
            end;
        until i>j;
        if l<j then sort(l,j);
        if i<r then sort(i,r);
      end;

   begin {quicksort};
     writeln('...Sorting');
     sort(Lo,Hi);
   end;

var no_pts3 : integer;

  begin{sort}
    file_flag:=false;
    last_drv:=lastdisk;
    clrscr;
    writeln('PC-Turbo Survey Point Sort Program. Ver 5.5 - 8907.10');
    writeln('Copyright 1987 by: Gary Argraves  All Rights Reserved');
    writeln('=====================================================');
    open_pt_file;
    for i:=1 to 3200 do new(c[i]);
    if file_flag then
      begin
        writeln('...Loading Point Coordinates');
        write('      Points Loaded');
        i:=0;
        repeat
          with c[i+1]^ do
            begin
              inc(i); if (100*trunc(i/100) = i) or (i=no_pts) then write(^M,i:4);
              if alt_flag then
                begin
                  {$I-}
                  seek(alt_pt_file,i); read(alt_pt_file,alt_pt_rec);
                  {$I+}
                  ok:=(IOResult=0);
                  p:=i;
                  x:=alt_pt_rec.alt_x;
                  str(x:5:0,s);
                  y:=alt_pt_rec.alt_y;
                  el:=alt_pt_rec.alt_z;
                end
              else
                begin
                  {$I-}
                  seek(pt_file,i); read(pt_file,pt_rec);
                  {$I+}
                  ok:=(IOResult=0);
                  p:=i;
                  x:=pt_rec.east;
                  str(x:5:0,s);
                  y:=pt_rec.north;
                  el:=pt_rec.elev;
                end;
            end;
        until (i=no_pts) or (not ok) or (i=3200);
        if i=3200 then begin no_pts3:=no_pts; no_pts:=3200; end;
        writeln;
        if not ok then
          begin
            writeln;
            writeln(^G,no_pts-(i-1):4,' Points have been lost.');
            writeln;
            writeln('Use the FLush option to avoid lost points. Also make sure');
            writeln('you EXit PC-TS before you reset or shut the computer off.');
            no_pts:=i-1;
            if alt_flag then
              begin
                alt_pt_rec0.alt_x:=i-1;
                seek(alt_pt_file,0);
                write(alt_pt_file,alt_pt_rec0);
              end
            else
              begin
                pt_rec0.from_pt:=i-1;
                seek(pt_file,0);
                write(pt_file,pt_rec0);
              end;
            writeln;
            write('...Press any Key');
            repeat until keypressed;
          end;
        writeln;
        QuickSort(1,no_pts);
        writeln('...Writing Sorted File');
        assign(sort_file,fn8);
        rewrite(sort_file);
        for i:=0 to no_pts do write(sort_file,c[i]^);
        if no_pts=3200 then
          begin
           writeln('Image of ',no_pts3,' points');
           for i:=3201 to no_pts3 do write(sort_file,c[1]^);
          end;
        if alt_flag then close(alt_pt_file) else close(pt_file);
        close(sort_file);
      end;
  end.
