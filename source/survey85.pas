unit survey85;
interface
uses crt,dos,survey0,basics2;

const
   cen = 1900;  { centry }
   wed = 1;     { week ending day }

   month : array[1..12] of string[3] =
    ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

    (*
function  jul_cal(julian:longint):string; { convert from julian to calender }
function  cal_jul(mdate:string):longint;  { subroutine to get the calender date }
procedure calendar(sd:string);
function  get_date:string;
*)

procedure clock;

implementation

function jul_cal(julian:longint):string; { convert from julian to calender }
  var year       : integer;
      day        : integer;
      month      : integer;
      leapday    : integer;
      dow        : integer;
      ms,ds,dows : string[2];
      ys         : string[4];
      i          : integer;
      d          : string;

  begin
    year:=trunc(julian/365.26)+1;
    day:=julian+trunc(395.25-365.25*year);
    IF int(year/4)*4 = year then     { calculate extra day for leapyear }
      leapday:=1 else leapday:=2;
    IF day > (91-leapday) then       { calculate actural number of days }
      day:=day+leapday;
    month:=trunc(day/30.57);           { generate actural month, day, year }
    day:=day-trunc(30.57*month);
    IF month > 12 then begin month:=1; year:=year+1; end;
    { set up the calender date.... }
    dow:=julian-trunc(julian/7)*7; if dow=0 then dow:=7;
    str(month:2,ms); str(day:2,ds); str(year:4,ys); str(dow:2,dows);
    d:=ms+'/'+ds+'/'+ys+dows;
    for i:=1 to length(d) do if d[i]=' ' then d[i]:='0';
    jul_cal:=d;
  end;

function cal_jul(mdate:string):longint;  { subroutine to get the calender date }
  var year    : integer;
      day     : integer;
      month   : integer;
      leapday : integer;
      dow     : integer;
      julian  : longint;
      err     : integer;   { used in julian dating }
  begin
    val(copy(mdate,1,2),month,err);
    val(copy(mdate,4,2),day,err);
    val(copy(mdate,7,4),year,err); if length(mdate)<9 then year:=year+cen;
    IF (month >12) OR (month <1) OR (day <1) OR (day >31) then
      begin cal_jul:=0; writeln('*** ERROR Illegal Date: ',mdate,' ***'); exit; end;
    { convert from calender to julian }
    julian:=trunc(30.57*month)+trunc(365.25*year-395.25)+day;
    { adjust the julian date if leapyear }
    IF month > 2 then
     IF trunc(year/4) = year/4 then julian:=julian-1
     ELSE julian:=julian-2;
   cal_jul:=julian;
  end;

procedure calendar(sd:string);
  var
    sd2    : string[12];
    jul    : longint;
    i,j,k  : integer;
    err    : integer;   { used in julian dating }
  begin
    if copy(sd,1,8)='00/00/00' then sd:='01/01/1900';
    sd2:=sd; sd[4]:='0'; sd[5]:='1'; jul:=cal_jul(sd)-1;
    if jul>0 then begin
      sd:=jul_cal(jul+1); val(copy(sd,11,2),k,err); k:=k-1;
      writeln;
      val(copy(sd,1,2),i,err);
      textcolor(white); writeln(month[i]:15,' ',copy(sd,7,4));
      textcolor(lightgray);
      writeln('Sun  Mon  Tue  Wed  Thu  Fri  Sat');
      if k>0 then write(' ':k*5);
      for i:=1 to 31 do
        begin
          jul:=jul+1; sd:=jul_cal(jul); val(copy(sd,11,2),k,err);
          if copy(sd,2,1)=copy(sd2,2,1) then
            begin if k=1 then writeln;
                  if k=wed then textcolor(white);
                  write(i:2,' ':3);
            end;
          textcolor(lightgray);
        end;
      writeln;
    end;
    writeln;
  end;

  function get_date:string;
    var s:string;
        key : char;
        x,y : integer;

    begin
      s:='';
      write('MM/DD/YY '); whereXY(x,y);
      repeat
        key:=chr(keyin3);
        if key in ['0'..'9','-','/',^H] then begin write(key); s:=s+key; end;
        if s[length(s)]=^H then
          begin delete(s,length(s),1); if length(s)>0 then delete(s,length(s),1); end;

        if s[length(s)] in ['/','-'] then
          case length(s) of
            2:s:='0'+s;
            5:s:=copy(s,1,3)+'0'+copy(s,4,2);
          end{case}
        else
          case length(s) of
            3:s:=copy(s,1,2)+'/'+copy(s,3,1);
            6:s:=copy(s,1,5)+'/'+copy(s,6,1);
          end{case};

        gotoxy(x,y); write(s);

      until key=^M;
      if length(s)<8 then get_date:='' else get_date:=s;
    end;

procedure clock;
var f:text;
    y,m,d,dow : word;
    ln1,ln2   : string;
    err       : integer;

  begin
    mode('CLock Calendar Setup');
    screen(cyan,black);
    getdate(y,m,d,dow);
    writeln('   SYSTEM DATE: ',m:2,'-',d:2,'-',y:4);

    ln1:='        '; ln2:='';

    assign(f,'\lastdate.bat'); {$I-} reset(f); readln(f,ln1); {$I+}
    if ioresult=0 then ln1:=copy(ln1,6,8);
    calendar(ln1);

    screen(cyan,black);
    writeln('        Last Date Used ',ln1);
    write('TODAY''S DATE  '); ln2:=get_date;
    if ln2='' then ln2:=ln1;
    val(copy(ln2,1,2),m,err);
    val(copy(ln2,4,2),d,err);
    val(copy(ln2,7,2),y,err); y:=y+cen;

    if ln2='' then ln2:='DATE '+ln1 else ln2:='DATE '+ln2;
    rewrite(f); writeln(f,ln2); close(f);
    setdate(y,m,d);
    writeln;
    getdate(y,m,d,dow);
    screen(yellow,black);
    writeln('   Current System Date ',m:2,'-',d:2,'-',y:4);
  end;


end.