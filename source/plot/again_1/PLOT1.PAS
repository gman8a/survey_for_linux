unit plot1;
interface
uses crt,
     basics4,
     filestuf;

{$I plotvar}

type
  line_type_rec_type = record
                          line_no      : byte;
                          line_type    : byte;
                          double_split : real;

                          no_pen_seg   : byte;
                          pen_segments : array[1..10] of real;

                          natural_line : byte;
                          box_str      : string[20];
                          letter_size  : byte;

                          marker_no    : byte;
                          marker_size  : byte;
                       end;

const user_line_type_cnt : integer = 0;
var   user_line_types    : array[1..30] of line_type_rec_type;

procedure read_user_line_types;

procedure init_pt_rec(var pt_rec:point);
procedure put3(pt:integer; sort_rec:sort_xyp);
procedure get(pt:integer; var pt_rec:point);
procedure set_no_pts(i:integer);
procedure put(pt:integer; pt_rec:point);
procedure rotate(var x,y:real; x2,y2:real; rot_ang:real);
function  Asz_Rad (asz: str16)  : real;
function  Bear_Rad(bear :str16) : real;
function  Rad_Asz (rad: real)   : str16;
function  Rad_Bear(rad: real)  : str16;
procedure ptpt(x1,y1,x2,y2: real;  var d:real; var asz:str16);
procedure Pt_to_Pt(p1,p2: integer; var d:real; var asz:str16);
function  tan(a:real) :real;
procedure Calculate(var pt_rec:point);
procedure Open_Pt_File;

implementation

{$I userline}

procedure init_pt_rec(var pt_rec:point);
  begin
    with pt_rec do
      begin
        from_pt:=0;
        bs_pt:=0;
        bs_ang:=0;
        f_dist:=0;
        hz_ang:=0;
        code:=0;
        descrip:='***';
        Setup:=false;
        aszmith:=0;
        distance:=0;
        north:=0;
        east:=0;
        hi:=0;
        vert_ang:=pi/2;
        rod:=0;
        elev:=0;
      end;
  end;

procedure put3(pt:integer; sort_rec:sort_xyp);
  begin
    seek(sort_file,pt);
    write(sort_file,sort_rec);
  end;

procedure get(pt:integer; var pt_rec:point);
  begin
    if pt<=no_pts then
      begin
        if (demo) and (pt>50) then pt:=1;    (* demo version *)
        if alt_flag then
          begin seek(alt_pt_file,pt); read(alt_pt_file,alt_pt_rec);
                init_pt_rec(pt_rec);
                with pt_rec,alt_pt_rec do
                  begin north:=alt_y; east:=alt_x;
                        elev:=alt_z; descrip:=alt_d;
                        if pt=0 then from_pt:=round(alt_x);
                  end;

          end
        else begin seek(pt_file,pt); read(pt_file,pt_rec); end;
      end;
  end;

procedure set_no_pts(i:integer);
   begin
     no_pts:=i;
     pt_rec0.from_pt:=no_pts;
     alt_pt_rec0.alt_x:=no_pts;
     if alt_flag then
          begin seek(alt_pt_file,0); write(alt_pt_file,alt_pt_rec0); end
     else begin seek(pt_file,0);     write(pt_file,pt_rec0); end;
   end;

procedure put(pt:integer; pt_rec:point);
  begin
    if pt<no_pts+2 then
      begin
        if alt_flag then
          begin seek(alt_pt_file,pt);
                with pt_rec,alt_pt_rec do
                  begin
                    alt_x:=east; alt_y:=north;
                    alt_d:=descrip; alt_z:=elev;
                    if pt=0 then alt_x:=from_pt;
                  end;
                write(alt_pt_file,alt_pt_rec);
          end
        else begin seek(pt_file,pt); write(pt_file,pt_rec); end;
        if pt=no_pts+1 then set_no_pts(no_pts+1);
      end;
  end;

procedure rotate(var x,y:real; x2,y2:real; rot_ang:real);
 var r,th :real;  { rotates Local rot_ang }
  begin
    x:=x-x2;
    y:=y-y2;
    r:=sqrt(x*x+y*y);  { rotate coordinates }

    if x<>0 then th:=arctan(abs(y/x)) else th:=pi/2;

    if x<0 then
      if y>0 then th:=pi-th else th:=pi+th
    else if y<0 then th:=2*pi-th;

    x:=cos(rot_ang*pi/180+th)*r;  { translate }
    y:=sin(rot_ang*pi/180+th)*r;
    x:=x+x2;
    y:=y+y2;
  end;

function Asz_Rad (asz: str16)  : real;

  var
    i,j,k    : integer;
    a1,a2    : integer;
    a3,a4    : real;
    ch       : char;

  procedure chk_asz_err;
    begin
      if j>0 then asz_err:=true;
    end;

  begin
    asz_err:=false;
    a1:=0; a2:=0; a3:=0;
    while copy(asz,1,1)=' ' do delete(asz,1,1);  { leading spaces }
    if length(asz)>0 then
      begin
        while copy(asz,length(asz),1)=' ' do delete(asz,length(asz),1); { trailing }
        for i:=1 to length(asz) do if not (asz[i] in ['-','.','0'..'9',' ']) then asz_err:=true;
        if (asz[1]='-') or (asz[length(asz)]='-') then asz_err:=true;
        if not asz_err then
          begin
            i:=pos('-',asz);
            if i>0 then
              begin
                k:=i-1;
                while (copy(asz,k,1)=' ') and (k>1) do k:=k-1;
                val(copy(asz,1,k),a1,j); chk_asz_err;
                delete(asz,1,i);
                while copy(asz,1,1)<'0' do delete(asz,1,1);
                i:=pos('-',asz);
                if i>0 then
                  begin
                    k:=i-1;
                    while (copy(asz,k,1)=' ') and (k>1) do k:=k-1;
                    val(copy(asz,1,k),a2,j); chk_asz_err;
                    delete(asz,1,i);
                    while copy(asz,1,1)<'0' do delete(asz,1,1);
                    val(asz,a3,j); chk_asz_err;
                  end
                else begin val(asz,a2,j); chk_asz_err; end;
              end
            else begin val(asz,a1,j); chk_asz_err; end;
          end;
      end
    else asz_err:=true;
    if asz_err then begin a4:=0; write(^G); end
    else a4:=(a1+a2/60+a3/3600)*pi/180;
    while a4>2*pi do a4:=a4-2*pi;
    asz_rad:=a4;
  end;

function Bear_Rad(bear :str16) : real;
  var
    a1 : real;
    i  : integer;
  begin
    asz_err:=false;
    for i:=1 to length(bear) do bear[i]:=upcase(bear[i]);
    for i:=1 to length(bear) do
      if not (bear[i] in ['-','.','S','N','E','W','0'..'9',' ']) then asz_err:=true;
    if (pos('N',bear)=0) and (pos('S',bear)=0) then asz_err:=true;
    if (pos('E',bear)=0) and (pos('W',bear)=0) then asz_err:=true;
    if not asz_err then
      begin
        if pos('N',bear)>0 then if pos('E',bear)>0 then a1:=0 else a1:=-2*pi
        else if pos('E',bear)>0 then a1:=-pi else a1:=pi;
        for i:=1 to length(bear) do if bear[i]>'9' then bear[i]:=' ';
        bear_rad:=abs(asz_rad(bear)+a1);
        if asz_err then bear_rad:=0;
      end
    else bear_rad:=0;
  end;

function Rad_Asz (rad: real)   : str16;
  var
    a1,a2  : integer;
    a3,a4  : real;
    a5,a6  : integer;
    p1,p2,
    p5,p6  : string[6];

  begin
    a4:=rad*(180/pi);
    a1:=trunc(a4);
    a2:=trunc((a4-a1)*60);
    a3:=(a4-a1-a2/60)*3600;
    if a3-trunc(a3)>=0.995 then begin a5:=trunc(a3)+1; a6:=0; end
    else begin a5:=trunc(a3); a6:=round((a3-a5)*100); end;
    if a5>=60 then begin a2:=a2+1; a5:=a5-60; end;
    if a2>=60 then begin a1:=a1+1; a2:=a2-60; end;
    while a1>=360 do a1:=a1-360;
    str(a1,p1); str(a2,p2); str(a5,p5); str(a6,p6);
    while length(p1)<3 do p1:=' '+p1;
    while length(p2)<2 do p2:=' '+p2;
    while length(p5)<2 do p5:=' '+p5;
    while length(p6)<2 do p6:='0'+p6;
    rad_asz:=p1+'-'+p2+'-'+p5+'.'+p6;
  end;

function Rad_Bear(rad: real)  : str16;
  var
    p1,p2 : char;
  begin
    if rad<=pi/2 then
      begin p1:='N'; p2:='E' end
    else if rad<=pi then
           begin p1:='S'; p2:='E'; rad:=pi-rad; end
         else if rad<=3*pi/2 then
                begin p1:='S'; p2:='W'; rad:=rad-pi end
              else begin p1:='N'; p2:='W'; rad:=2*pi-rad; end;
    rad_bear:=p1+rad_asz(rad)+p2;
  end;

procedure ptpt(x1,y1,x2,y2: real;  var d:real; var asz:str16);
var
    n,e,a   : real;
    q       : integer;
  begin
        n:=y2-y1;
        e:=x2-x1;
        q:=1;
        if n>0 then q:=2 else if (n=0) and (e>0) then q:=2;
        if n=0 then a:=pi/2 else a:=arctan(e/n);
        a:=a+q*pi;
        asz:=rad_asz(a);
        d:=sqrt(n*n+e*e);
  end;

procedure Pt_to_Pt(p1,p2: integer; var d:real; var asz:str16);
  var
    pt_rec,
    pt_rec2 : point;
  begin
    get(p1,pt_rec);
    get(p2,pt_rec2);
    ptpt(pt_rec.east,pt_rec.north,pt_rec2.east,pt_rec2.north,d,asz);
  end;

 function tan(a:real) :real;
  begin
    tan:=sin(a)/cos(a);
  end;

procedure Calculate(var pt_rec:point);
  var
    pt_rec2  : point;
    de,a,a1  : real;
    asz      : str16;

  begin
    pt_err:=false;
    get(abs(pt_rec.from_pt),pt_rec2);
      if (pt_rec.from_pt>0) and (pt_rec.from_pt<=no_pts) then
        with pt_rec do
          begin
                 begin
                   if bs_pt<>0 then pt_to_pt(from_pt,abs(bs_pt),a,asz)
                   else asz:='0';     { due north back sight }
                   a:=asz_rad(asz);   { back site aszmith }
                 end;
            if bs_pt=0 then a:=0;
            while a<0 do a:=a+2*pi;
            if code=0 then  { figure hz_ang right off bs_ang=0 }
              begin
                a1:=abs(a-aszmith);
                if a>aszmith then hz_ang:=2*pi-a1 else hz_ang:=a1;
              end
            else { figure aszmith from hz_ang }
              begin
                 if code=1 then a1:=a+hz_ang else a1:=a-hz_ang;
                 while a1<0 do a1:=a1+2*pi;
                 while a1>2*pi do a1:=a1-2*pi;
                 aszmith:=a1;
              end;
            north:=pt_rec2.north+cos(aszmith)*distance;
            east :=pt_rec2.east +sin(aszmith)*distance;
          end{with pt_rec}
          else pt_err:=true;
      if (pt_rec.rod>0) and (pt_rec.from_pt<>0) then with pt_rec do
        begin
          de:=tan(abs(vert_ang-pi/2))*distance;
          if vert_ang>pi/2 then de:=-de;
          elev:=pt_rec2.elev+pt_rec2.hi-rod+de;
        end;
  end;

procedure Open_Pt_File;
  var
    i       : integer;
    sort_rec: sort_xyp;

  begin
    file_flag:=false;
    alt_flag:=false;
    write(^G,'Coordinate file name: ');
    if paramCount>0 then
      begin
        fn:=paramStr(1);
        writeln(fn);
      end
    else
      begin
        fn:='';
        write(' ? ');
        readln(fn);
      end;
    while copy(fn,1,1)=' ' do delete(fn,1,1);
    for i:=1 to length(fn) do fn[i]:=upcase(fn[i]);
    if length(fn)>0 then
      begin
        i:=length(fn)+1;
        repeat i:=i-1; until (i=0) or (fn[i]='.');
        if i>1 then if fn[i-1]='.' then i:=0;
        if i>0 then
          begin
            if length(fn)>=i+1 then
              case fn[i+1] of
                'A':begin alt_flag:=true;
                          if length(fn)>=i+2 then
                            case fn[i+2] of
                              ':':begin {sign_on_flg:=false;} end;
                            end{case};
                    end;
                ':':begin {sign_on_flg:=false;} end;
              end{case};
            fn:=copy(fn,1,i-1);
          end;
        fn2:=fn+'.BAL';
        fn3:=fn+'.LN';
        fn4:=fn+'.LED';
        fn5:=fn+'.AR';
        fn6:=fn+'.PT0';
        fn7:=fn+'.';
        fn8:=fn+'.SRT';
        if fn[2]<>':' then
          begin
            fn7:=last_drv+':'+fn7;  { rotation file, write to ram drive }
            fn8:=last_drv+':'+fn8;
          end
        else
          begin
            fn7[1]:=last_drv;
            fn8[1]:=last_drv;
          end;
        { parse path out of fn7, fn8 }
        i:=length(fn7); repeat i:=i-1; until (i=0) or (fn7[i]='\');
        if i>0 then delete(fn7,3,i-2);
        i:=length(fn8); repeat i:=i-1; until (i=0) or (fn8[i]='\');
        if i>0 then delete(fn8,3,i-2);
        if alt_flag then
          begin write('Alternate ');
                fn:=fn+'.PA'; assign(alt_pt_file,fn);
                {$I-}  reset(alt_pt_file);  {$I+} end
        else begin fn :=fn+'.PT'; assign(pt_file,fn);
                {$I-}  reset(pt_file);  {$I+} end;
        if IOresult=0 then
          begin
            writeln('==> Existing Point File Opened'); writeln;
            no_pts:=0;
            get(0,pt_rec0);
            writeln('File Description : ',pt_rec0.descrip);
            alt_pt_rec0.alt_d:=pt_rec0.descrip;
            no_pts:=pt_rec0.from_pt;
            no_pts2:=no_pts;
            file_flag:=true;
          end
        else
          begin
            quest2(0,0,'File does not exist, Create File (Y/N) ? ',['Y','N'],false);
            if response='Y' then
              begin
                if alt_flag then rewrite(alt_pt_file) else rewrite(pt_file);
                writeln('==> New Point File Created'); writeln;
                write(^G,'Enter File Description (20 char) ? ');
                readln(pt_rec0.descrip);
                alt_pt_rec0.alt_d:=pt_rec0.descrip;
                pt_rec0.from_pt:=0;
                pt_rec0.code:=1;
                pt_rec0.bs_ang:=0;
                pt_rec0.f_dist:=0;
                pt_rec0.bs_pt:=0;
                pt_rec0.rod:=0;
                pt_rec0.setup:=true;
                pt_rec0.aszmith:=0;
                no_pts:=0;
                put(0,pt_rec0);
                file_flag:=true;
                assign(sort_file,fn8);
                rewrite(sort_file);
                put3(0,sort_rec);
              end
            else begin writeln; writeln(get_dir(copy(fn,1,1)+'*.PT',false)); end;
          end;
        if file_flag then writeln(' Number of Points =',no_pts:4);
      end;
    dig_des:='****';
  end;

begin
  read_user_line_types;
end.
