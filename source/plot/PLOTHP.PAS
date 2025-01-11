unit plothp;
interface
uses plot1,basics2;

var
      page_size : char;
      plt_x,plt_y   : real;
      rot_flag      : integer;
      otf_x,otf_y   : real;  { origin translation factor X,Y }
      hard         : boolean;  { true means hardware handshake is set }

var
   i,j,k,l     : integer; { general }
   cur_pen     : integer; { current pen }
   cur_ln      : integer; { current line type }
   cur_chr     : integer; { Current char type }
   cur_marker  : integer;
   cur_size    : real;    { current marker size }
   cur_x,cur_y : real;    { current x-y pen position }
   cur_slant   : real;    { last slant ang for letter print }
   cur_cs      : real;    { current char size }
   cur_ch      : real;    { current char height }
   cur_m       : integer;
   cur_s       : real;
   cur_l       : integer;
   rot_ang     : real;    { coordinate rotation angle (degrees) }
   xt,yt       : real;    { coordinate translation }
   V_offset    : real;    { verticle offset of print from slope line }
   pt_end      : integer; { to tell line command to draw line ends }
   t_code      : char;    { type code of printed figures of plotted lines }
   t_code2     : char;
   perp_ang    : real;    { angle to plot perpendicular labels }
   curve_arr   : array[1..100,1..2] of real;  { for general polly line curves }

     n_low,e_low   : real;    { overall plot window coordinate }
     n_up, e_up    : real;
     n_low2,e_low2 : real;    { local plot window (on single page }
     n_up2, e_up2  : real;
     scale         : integer; { drawing scale ft/inch }
     at_scale      : integer; { for scaleing characters }
     n_pages       : integer; { number of north pages in this plot }
     e_pages       : integer; { number of east pages in this plot  }
     n_ft,e_ft     : real;    { north feet per page, east ft/page }
     pt_Xhair      : integer; { >0 if plot points }
     c_scale       : real;  { char scale factor .67 = 30 Scale }
     m_scale       : real;  { marker scale }
     xoo,yoo       : real;  { plotter origin }
     p1_p2_dist    : real;

const
     pu       : integer =3;   { pen up }
     pd       : integer =2;   { pen down }
     init     : integer =0;   { initialize to power up state }
     x_scale  : real = 1.00;
     y_scale  : real = 1.00;

     fast     : integer =16;  { plotter Pen speed 4 inches/sec}
     slow     : integer =10;

procedure adj_ang(var angle:real);
procedure plt_reset;
procedure prform(i:integer);
procedure plot(x,y:real; code:integer); { x,y inches }
procedure plt_select;
procedure plt_pause;
procedure circle(x,y,r,a1,a2 :real);   { x,y=center pt.,  a1-start a2-end angles from due east }
procedure set_line(i:integer; d:real);
procedure dashs(i:integer); { pass the line type }
procedure char(i,j: REAL; code:integer);
procedure setchr(ch,cs,slant:real;  emphasis:integer);
procedure newpen(i:integer);
procedure symbol(x,y:real; char_type:integer;
                   angle:real; p_str :string; pen:integer); { inches and degress }
procedure poly_curve(np:integer); { np = # coordinate pairs in curve_arr }
procedure ellipse(x3,y3,x4,y4,ellipse_ratio{W/L}:real);
procedure mark_shape(x,y,size :real; m_type:integer);  { x-y center, size-inches }
procedure marker(x,y,size :real; m_type :integer);  { size-inches }
procedure line(x1,y1,x2,y2:real; pt_end:integer);
procedure init_plot;

implementation

function  max(r1,r2:real):real; begin if r1>r2 then max:=r1 else max:=r2; end;
function  min(r1,r2:real):real; begin if r1<r2 then min:=r1 else min:=r2; end;

procedure adj_ang(var angle:real);
  begin
    while angle>360 do angle:=angle-360;
    while angle<000 do angle:=angle+360;
  end;

procedure plt_reset;
  begin
     writeln(out_file,'PU 0,0;');  { Home pen }
     writeln(out_file,'SP 0;');    { Select pen # 0 }
     writeln(out_file,^[,'.);');   { deselect plotter }
  end;

procedure prform(i:integer);
  begin
    if i>23 then i:=23; { i is in inches/sec. }
    i:=round(i*2.54); { cm./sec }
    writeln(out_file,'VS ',i:2,';');         { Pen velocity 0 or 1 }
  end;

procedure plot(x,y:real; code:integer); { x,y inches }
  begin
    x:=x*plt_x_mf*x_scale+xoo;   { change inches to plotter units }
    y:=y*plt_y_mf*y_scale+yoo;   { plotter set for .001 inches per movement unit }
    if code=0 then
      begin   { INITialize plotter Home, .001 in., absolute address }
          cur_x:=-100;
          cur_y:=-100;
          cur_pen:=0;
          cur_ln:=-1;
          cur_chr:=-1;
          cur_slant:=0;
          cur_marker:=-1;
          cur_size:=0.08; { size 2 }
          perp_ang:=0;
          c_scale:=1;
          m_scale:=1;
      end;
    if (abs(cur_x-x)>0.001) or (abs(cur_y-y)>0.001) or (abs(code)=2) then
    case code of
    -3,3:writeln(out_file,'PU ',x:5:0,',',y:5:0,';'); { Pen UP  }
    -2,2:begin
           writeln(out_file,'PD ',x:5:0,',',y:5:0,';'); { Pen DOWN }
           if (x<0) or (x>33850.0) {plt_x*mf_plt_x} then writeln(out_file,'PU;')
           else if (y<0) or (y>21400.0) {plt_y*mf_plt_y} then writeln(out_file,'PU;');
         end;
    end{case};
    if code<0 then begin xoo:=x; yoo:=y; end;
    cur_x:=x;
    cur_y:=y;
  end;

procedure plt_select;
  begin
    writeln(out_file,^[,'.(; DF;');     { select plotter, default conditions }
    writeln(out_file,'CS0; DT3; LO1;'); { char. set, label terminator, label origin }
    if hard then
      begin
        writeln(out_file,^[,'.@10000;3:');  { HARDWARE HAND SHAKE; set buffer size }
        writeln(out_file,^[,'.P3:');
      end
    else
      begin
        writeln(out_file,^[,'.P1:');
        writeln(out_file,^[,'.I81;;17:');
        writeln(out_file,^[,'.N10;19:');
      end;
    writeln(out_file,'IN;');
    if (page_size in ['C','Z']) or ((page_size='O') and (rot_flag<>0)) then
      begin
        writeln(out_file,'RO 90; IP;'); { rotate, set P1,P2 @ default }
        xoo:=plt_x_mf; plt_x_mf:=plt_y_mf; plt_y_mf:=xoo;
      end;
    xoo:=0;
    yoo:=0;
  end;

procedure plt_pause;
   begin
     writeln(out_file,'PU 0,0;');  { Home pen & VIEW the plotter }
     writeln(out_file,'SP 0;');    { Select pen # 0 }
     writeln(out_file,'NR;');
   end;

procedure circle(x,y,r,a1,a2 :real);   { x,y=center pt.,  a1-start a2-end angles from due east }
var
  x2,y2    : real;
  x3,y3    : real;
  d        : real; { arc delta in degrees }
  ct       : real;

  begin
    d:=a2-a1;                      { degrees of rotation }
    adj_ang(d);
    d:=-(360-d);
    if d=0 then d:=360;
    x2:=(x+cos(a1*pi/180)*r);      { start of arc }
    y2:=(y+sin(a1*pi/180)*r);
    x3:=(x+cos(a2*pi/180)*r);      { end of arc }
    y3:=(y+sin(a2*pi/180)*r);
    x:=x*plt_x_mf*x_scale+xoo;         { center point }
    y:=y*plt_y_mf*y_scale+yoo;
    plot(x2,y2,pu);                { move to start of arc }
    writeln(out_file,'PD;');
(*    plot(x2,y2,pd);  *)
    case round(r*10) of
      0..1:ct:=20;
      2..3:ct:=15;
      4..5:ct:=8;
      6..7:ct:=4;
      8..10:ct:=2;
      else ct:=1;
    end{case};
    writeln(out_file,'AA ',x:5:0,',',y:5:0,',',d:7:2,',',ct:4:1,';');
       { plotter @ end of arc }
    cur_x:=-100;
    cur_y:=-100;
  end;

(*
procedure set_line(i,d:integer); { line type,  percent length of pattern }
  var
    pl : real; { pattern length }
  begin
     pl:=d/100 *  10.42{ A size }/p1_p2_dist * (plt_x_mf*p1_p2_dist);
     if i=0 then writeln(out_file,'LT;')
     else { writeln(out_file,'LT ',i:2,',',pl:6:1,';');   line type }
       writeln(out_file,'LT ',i:2,';');
  end;

procedure dashs(i:integer); { pass the line type }
  begin
    if i<>cur_ln then
      case i of
        0:set_line(0,0);  { solid line }
        1:set_line(3,4);  { Dashed line 2 }
        2:set_line(5,4);  { Street/Center Line }
        3:set_line(6,4);  { Property Line 1 }
        4:set_line(1,1);  { Dotted Line 2 }
        5:set_line(4,4);  { Property Line 2 }
        6:set_line(2,1);  { Dashed Line 1 }
        7:set_line(2,3);  { Dashed line 3 }
        8:set_line(3,1);  { Dashed line 4 }
       14:set_line(1,0);  { Dotted Line 1 }
       15:set_line(2,5);  { wide space dashed }
      end{case};
    cur_ln:=i;
  end;
*)

procedure set_line(i:integer; d:real); { line type,  percent length of pattern }
  begin
     if i=0 then writeln(out_file,'LT;')
     else writeln(out_file,'LT ',i:2,',',d:5:2,';');  { line type }
  end;

procedure dashs(i:integer); { pass the line type }
  begin
    if i<>cur_ln then
      case i of
        0:set_line(0,0.0);  { solid line }
        1:set_line(3,0.36);  { Dashed line 2 }
        2:set_line(6,1.1);  { Street/Center Line }
        3:set_line(5,0.9);  { Property Line 1 }
        4:set_line(2,0.18);  { Dotted Line 2 }
        5:set_line(5,1.5);  { Property Line 2 }
        6:set_line(2,0.25);  { Dashed Line 1 }
        7:set_line(3,0.7);  { Dashed line 3 }
        8:set_line(3,1.2);  { Dashed line 4 }
       14:set_line(2,0.15);  { Dotted Line 1 }
       15:set_line(4,1.3);  { wide space dashed }
      end{case};
    cur_ln:=i;
  end;

procedure char(i,j: REAL; code:integer);
 VAR
   CH,CW   : real;      { Character Height & width }
   x,y     : real;
  begin
    case code of
      0:writeln(out_file,'SI; DI;');  { reset all character attributes }
      1:BEGIN
          CH:=I*C_SCALE*2.54;
          CW:=J*C_SCALE*2.54;
          if j=0 then CW:=ch*6/7;
          cw:=0.658*cw;
          writeln(out_file,'SI ',cw:6:3,',',ch:6:3,';'); { character height and width }
        END;
      2:V_Offset:=I; { Set Verticle offset print slope line (symbols) }
      3:begin
          x:=cos(i*pi/180)*100;
          y:=sin(i*pi/180)*100;
          writeln(out_file,'DI ',x:5:0,',',y:5:0,';');   { Line direction }
        end;
      4:if i=0 then writeln(out_file,'SL;')         { char. slant degrees or italic }
        else writeln(out_file,'SL ',tan(i*pi/180):6:4,';');
      5:begin end; { Set Emphasis mode i=0-3, DMP bold set for power up only }
    end;
  end;

procedure setchr(ch,cs,slant:real;  emphasis:integer);
 { char height, char spacing, slant angle, emp. mode 0-3 }
  begin
    char(slant,0,4);
    char(ch,cs,1);
    if cs<>0 then cur_cs:=cs*6/7 else cur_cs:=6/7*ch;
    cur_ch:=ch;
    char(emphasis mod 4,0,5);
  end;

procedure newpen(i:integer);
  begin
    i:=i mod 9; if i=0 then i:=1;
(*    i:=1; { only one pen } *)
    if cur_pen<>i then
      begin
        writeln(out_file,'SP ',i:1,';');   { Select pen # 1 -4 }
(*        plt_pause;
        writeln(^G,'===>>> Mount Pen #',i:2,'...Press <SPACE BAR>');
        quest(0,0,'',[' '],false); *)
      end;
    cur_pen:=i;
  end;

procedure symbol(x,y:real; char_type:integer;
               angle:real; p_str :string; pen:integer);
           { inches and degress }
  var i:integer;
      x2,y2:real;
      a1:real;
  begin
    adj_ang(angle);
    if cur_chr<>char_type then
      begin
        case char_type of
          0:{Set by set char};
          1:setchr(0.13,0.11,0,0); {standard}
          2:setchr(0.40,0.36,10,2);
          3:setchr(0.20,0.18,0,3);
          4:setchr(0.17,0.13,20,4);
          5:setchr(0.09,0.07,0,0);
          6:setchr(0.105,0.088,0,0);
          7:setchr(0.105,0.088,20,0);  { italic letter }
        end{case};
        cur_chr:=char_type;
      end;
    if (angle>95) and (angle<275) then
      begin
        i:=length(p_str);
(*        while (p_str[i]=' ') and (i>1) do i:=i-1;  *)
        if i=0 then i:=1;
        a1:=angle+arctan(cur_ch/(cur_cs*i))*180/pi;
        x2:=x+sqrt(sqr(cur_ch)+sqr(cur_cs*i));
        y2:=y;
        rotate(x2,y2,x,y,a1);
        x:=x2;
        y:=y2;
        angle:=angle+180;
      end;
    newpen(pen);
    char(angle,0,3);
    plot(x,y,pu);
    writeln(out_file,'LB',p_str:length(p_str),^C);
    cur_x:=-100;
    cur_y:=-100;
  end;

procedure poly_curve(np:integer); { np = # coordinate pairs in curve_arr }
  { the first point is so that the tangent around the point 2 is as desired }

 var  d,u,w,p : array[1..100] of real;

  procedure makespline; { start, number of points }
    var i: integer;
    begin
      for i:=2 to np-1 do
        begin d[i]:=2.0*(curve_arr[i+1,1]-curve_arr[i-1,1]);
              if d[i]=0 then d[i]:=0.1;
        end;
      for i:=1 to np-1 do
        begin u[i]:=curve_arr[i+1,1]-curve_arr[i,1];
              if u[i]=0 then u[i]:=0.1;
        end;
      for i:=2 to np-1 do w[i]:=6.0*((curve_arr[i+1,2]-curve_arr[i,2])/u[i]-
                                     (curve_arr[i,2]-curve_arr[i-1,2])/u[i-1]);
      p[1]:=0.0; p[np]:=0.0;
      for i:=2 to np-2 do
        begin w[i+1]:=w[i+1]-w[i]*u[i]/d[i];
              d[i+1]:=d[i+1]-u[i]*u[i]/d[i];
        end;
      for i:= np-1 downto 2 do p[i]:=(w[i]-u[i]*p[i+1])/d[i];
    end;

  function eval(v:real; i:integer):real;
    var t,hi,ai,dummy: real;
      function f(x:real):real; begin f:=x*x*x-x; end;
    begin
(*      t:=(v-curve_arr[i,1])/u[i];
      eval:=t*curve_arr[i+1,2]+(1-t)*curve_arr[i,2]+u[i]*u[i]*(f(t)*p[i+1]-f(1-t)*p[i]);
*)
      dummy:=v-curve_arr[i,1];
      hi:=u[i]; { =X[i+1]-X[i]; }
      ai:=dummy*(p[i+1]-p[i])/(6.0*hi)+p[i]/2.0;
      ai:=dummy*ai+(curve_arr[i+1,2]-curve_arr[i,2])/hi-hi*(2.0*p[i]+p[i+1])/6.0;
      eval:=dummy*ai+curve_arr[i,2];
    end;

  var i     : integer;
      x1,x2 : real;

  procedure spline_plot;
    begin
      write(out_file,',',x1:5:0,',',eval(x1,i):5:0);
    end;

  begin
    for i:=1 to np do
      begin
        curve_arr[i,1]:=curve_arr[i,1]*plt_x_mf*x_scale+xoo;   { change inches to plotter units }
        curve_arr[i,2]:=curve_arr[i,2]*plt_y_mf*y_scale+yoo;   { plotter set for .001 inches per movement unit }
      end;
    makespline;
    writeln(out_file,'PU ',curve_arr[2,1]:5:0,',',curve_arr[2,2]:5:0,';');
    write(out_file,  'PD ',curve_arr[2,1]:5:0,',',curve_arr[2,2]:5:0);
    i:=2;
    repeat
      x1:=curve_arr[i,1]; x2:=curve_arr[i+1,1];
      if x1<x2 then
        while x1<x2 do begin x1:=x1+50.0; if x1>x2 then x1:=x2; spline_plot; end
      else
        while x1>x2 do begin x1:=x1-50.0; if x1<x2 then x1:=x2; spline_plot; end;
      i:=i+1;
    until i=np-1;
    writeln(out_file,';');
   end;

procedure ellipse(x3,y3,x4,y4,ellipse_ratio{W/L}:real);
 var
   a1,a2     : real;
   asz       : str16;
   fx,fy     : real; { focus points }
   a,l,w,d,c : real;
   r1,r2     : real;
   i,j       : integer;
   d1,d2     : real;
   d3,d4     : real;
   k         : real;

  begin
    x3:=x3*plt_x_mf*x_scale+xoo;
    x4:=x4*plt_x_mf*x_scale+xoo;
    y3:=y3*plt_y_mf*y_scale+yoo;
    y4:=y4*plt_y_mf*y_scale+yoo;
    ptpt(x3,y3,x4,y4,l,asz);  { l=length }
    w:=ellipse_ratio*l;       { w=width }
    a:=sqrt(l*l-w*w)/2;       { distance from origin to focus }
    d:=l/2-a;                 { distance from end to focus }
    c:=2*sqrt(a*a+w*w/4);     { fixed length of string }
    a1:=asz_rad(asz);         { aszmith along major axis from focus 1 }
    fx:=x3+sin(a1)*d;         { compute x,y of focus points }
    fy:=y3+cos(a1)*d;
    i:=0;
    d1:=2*a;
    d2:=(2*a+c)/2;
    d4:=d2-d1;
    case round(l) of            { smoothness of curve }
         0.. 250:k:=c/8;
       251.. 500:k:=c/12;
       501..1000:k:=c/20;
      1001..1500:k:=c/32;
       else k:=c/40;
     end{case};
    r1:=d+k/4;
    w:=c-d;                   { to reduce calculation time }
    writeln(out_file,'PU ',x3:5:0,',',y3:5:0,';');
    write(  out_file,'PD ',x3:5:0,',',y3:5:0);
    repeat
      r2:=c-r1;
      d3:=d4*(d2-r1)/(d1*r1);
      a2:=arctan(sqrt(d3/(1-d3)))*2;
      write(out_file,',',fx+sin(a1+a2)*r1:5:0,',',fy+cos(a1+a2)*r1:5:0);
      i:=i+1;
      curve_arr[i,1]:=fx+sin(a1-a2)*r1;
      curve_arr[i,2]:=fy+cos(a1-a2)*r1;
      if i<4 then r1:=r1+k/4 else r1:=r1+k;
    until r1>=w;
    write(out_file,',',x4:5:0,',',y4:5:0);
    for j:=i downto 1 do
      write(out_file,',',curve_arr[j,1]:5:0,',',curve_arr[j,2]:5:0);
    writeln(out_file,',',x3:5:0,',',y3:5:0,';');
  end;

procedure mark_shape(x,y,size :real; m_type:integer);  { x-y center, size-inches }
  var
    x2,y2 : real;
    h1,h2 : real;
    flag_1: boolean;
    s     : real;
    ang   : real;

   procedure plot_rot;
     begin
       rotate(x,y,x2,y2,cur_slant);
       if not flag_1 then begin flag_1:=true; plot(x,y,pu) end
       else plot(x,y,pd);
     end;

  begin
    x2:=x;
    y2:=y;
    s:=size/2;
    flag_1:=false;
    case m_type of
      0:begin  {x-hairs}
          x:=x2-s; y:=y2; plot_rot;
          x:=x2+s; y:=y2; plot_rot;
          flag_1:=false;
          x:=x2; y:=y2-s; plot_rot;
          x:=x2; y:=y2+s; plot_rot;
        end;
      1:begin { X cross Hair }
          h1:=tan(35*pi/180)*s;
          x:=x2-h1; y:=y2-s; plot_rot;
          x:=x2+h1; y:=y2+s; plot_rot;
          flag_1:=false;
          x:=x2+h1; y:=y2-s; plot_rot;
          x:=x2-h1; y:=y2+s; plot_rot;
        end;
      2:begin  {square}
          x:=x2-s; y:=y2-s; plot_rot;
          x:=x2+s; y:=y2-s; plot_rot;
          x:=x2+s; y:=y2+s; plot_rot;
          x:=x2-s; y:=y2+s; plot_rot;
          x:=x2-s; y:=y2-s; plot_rot;
        end;
      3:begin {pengon}
          h1:=pi/6;
          repeat
            x:=x2+sin(h1)*s;
            y:=y2+cos(h1)*s;
            plot_rot;
            h1:=h1+pi/3;
          until h1>pi*(2+1/3);
        end;
      4:begin {triangle}
          s:=size/tan(pi/3);
          h1:=tan(pi/6)*s;
          h2:=size-h1;
(*          plot(x2,y2,pu); plot(x2,y2,pd);   { dot the center }  *)
          x:=x2-s; y:=y2-h1; plot_rot;
          x:=x2+s; y:=y2-h1; plot_rot;
          x:=x2;   y:=y2+h2; plot_rot;
          x:=x2-s; y:=y2-h1; plot_rot;
        end;
      5:begin { double triangle cross Hair }
          h1:=tan(35*pi/180)*s;
          x:=x2-s;  y:=y2-h1; plot_rot;
          x:=x2+s;  y:=y2+h1; plot_rot;
          x:=x2+s;  y:=y2-h1; plot_rot;
          x:=x2-s;  y:=y2+h1; plot_rot;
          x:=x2-s;  y:=y2-h1; plot_rot;
        end;
      6:circle(x2,y2,s,0,360);
      7:begin  {North Arrow}
          cur_slant:=rot_ang;
          x:=x2;     y:=y2+s/4;     plot_rot;
          x:=x2-s/8; y:=y2+s/2;     plot_rot;
          x:=x2;     y:=y2+s;       plot_rot;
          x:=x2;     y:=y2-3/4*s;   plot_rot;
          x:=x2-s/8; y:=y2-s;       plot_rot;
          x:=x2;     y:=y2-s/4;     plot_rot;
          flag_1:=false;
          x:=x2-s/8; y:=y2;         plot_rot;
          x:=x2+s/8; y:=y2;         plot_rot;
          circle(x2,y2,s/8,0,360);
          setchr(s/4,s/4,0,0);
          x:=x2-s/10; y:=y2+s;
          rotate(x,y,x2,y2,rot_ang);
          symbol(x,y,0,rot_ang,'N',cur_pen);
          x:=x2-s/10-0.02*s/2; y:=y2+s;
          rotate(x,y,x2,y2,rot_ang);
          symbol(x,y,0,rot_ang,'N',cur_pen);
        end;
      8:begin {True North}
        end;
      9:begin end; {No Marker}
     10:begin  {pole}
          circle(x2,y2,s,0,360);
          x:=x2-3/2*s; y:=y2;  plot_rot;
          x:=x2+3/2*s; y:=y2;  plot_rot;
        end;
     11:begin { Tree 1 }
          h1:=s/(1+2*sin(15*pi/180));  { radius that r1 radius are on }
          h2:=s-h1;
          ang:=360;
          repeat
            ang:=ang-60;
            x:=x2+h1; y:=y2;
            rotate(x,y,x2,y2,cur_slant+ang); { x,y= center of busch }
            circle(x,y,h2,cur_slant+ang+105,cur_slant+ang-105);
          until ang<=0;
          circle(x2,y2,h1/5,0,360);
        end;
     12:begin { Tree 2 }
          h1:=s;  { radius that r2 radius are on }
          h2:=2*s*sin(15*pi/180);
          ang:=0;
          repeat
            ang:=ang+60;
            x:=h1+x2; y:=y2;
            rotate(x,y,x2,y2,cur_slant+ang); { x,y= center of busch }
            circle(x,y,h2,cur_slant+ang-105,cur_slant+ang+105);
          until ang>=360;
          circle(x2,y2,h1/7,0,360);
        end;
     13:begin { Rock Boundary }
          ang:=-45;
          repeat
            ang:=ang+90;
            x:=x2+s/3; y:=y2; rotate(x,y,x2,y2,cur_slant+ang);
            h1:=x2+s; h2:=y2; rotate(h1,h2,x2,y2,cur_slant+ang);
            ellipse(x,y,h1,h2,0.44);
          until ang>=315;
          circle(x2,y2,s/6,0,360);
        end;
    end{case};
  end;

procedure marker(x,y,size :real; m_type :integer);  { size-inches }
  var
    i:integer;
  begin   { 0= + 1=X   2=square   3=octagon  4=triangle  5=dbl. tri. 6=circle }
    size:=size*m_scale;
    if m_type>0 then
      begin
        cur_marker:=m_type;
        cur_size:=size;
      end;
    i:=cur_ln;
    dashs(0); { Set Solid Line }
    case m_type of
       0..99:mark_shape(x,y,size,m_type);
       100:begin
               plot(x,y,pu);
               size:=size*plt_y_mf/4;
(*               writeln(out_file,'M(S',size:3:0,')',m_type:1);  *)
             end;
    end{case};
    dashs(i); { reset cur_ln type }
  end;

procedure line(x1,y1,x2,y2:real; pt_end:integer);
  var
    x3,y3   : real;
    x4,y4   : real;
    ln_len  : real;
    seg_len : real;
    a1      : real;
    asz     : str16;
    i       : integer;
    cur_l   : integer;

  procedure segment(seg_no:integer; tolerance:real; var xs,ys:real);
    begin
      if ln_len-seg_len*seg_no>=-seg_len*tolerance then
        begin
          xs:=x1+sin(a1)*seg_no*seg_len;
          ys:=y1+cos(a1)*seg_no*seg_len;
        end
      else begin xs:=0; ys:=0; end
    end;

  begin
    x3:=x2-x1;
    y3:=y2-y1;
    if abs(x3)<0.001 then if y3>0 then cur_slant:=90 else cur_slant:=270
    else cur_slant:=arctan(y3/x3)*180/pi;
    cur_m:=cur_marker;
    cur_s:=cur_size;
    cur_l:=cur_ln;
(*    if cur_ln<>9 then   *)
        if (pt_end in [1,3]) and (x1<34.0) and (x1>-34.0)
           and (y1<32.7) and (y1>-33.7) then
           case pt_xhair of
             1:marker(x1,y1,0.07/m_scale,0);   { x-hair }
             2:marker(x1,y1,0.0355/m_scale,6); { small circle }
           end{case};
    if cur_ln in [0..8,14,15] then { use standard plotter line }
       begin plot(x1,y1,pu); plot(x2,y2,pd); end
    else if cur_ln>9 then  { draw our special lines }
        begin
          ptpt(x1,y1,x2,y2,ln_len,asz);
          a1:=asz_rad(asz);
          case cur_l of
             10:begin  {stone wall}
                               {min size} {max size}
                  dashs(0); { set solid Line }
                  seg_len:=max(0.07,min(0.16,0.15*30/scale)); { inches }
                  seg_len:=max(min(seg_len*m_sf,0.16),0.07);
                  i:=0;
                  x3:=x1; y3:=y1; {start of rock}
                  repeat
                    i:=i+1;
                    segment(i,0.33,x4,y4); {end of rock}
                    if x4<>0 then
                      ellipse(x3,y3,x4,y4,0.44 {height/width ellipse_ratio });
                    x3:=x4; y3:=y4;
                  until x4=0;
                end;
             11:begin {Fence}
                  dashs(0); { set solid Line }
                  cur_slant:=cur_slant+45;
                  i:=0;
                  x3:=x1; y3:=y1; {start of fence}
                  repeat
                    seg_len:=i*0.38+0.30; segment(1,0.0,x4,y4); {fence end}
                    plot(x3,y3,pu);
                    if x4<>0 then plot(x4,y4,pd) else plot(x2,y2,pd);
                    seg_len:=i*0.38+0.34; segment(1,0.0,x4,y4);
                    if x4<>0 then
                      marker(x4,y4,max(0.06,min(0.11,0.07*40/scale*m_sf/m_scale)),0);
                    i:=i+1;
                    seg_len:=i*0.38; segment(1,0.0,x3,y3); { new start }
                  until x3*x4=0;
                  cur_slant:=cur_slant-45;
                end;
             12:begin {Stone Wall & Fence}
                  dashs(0); { set solid Line }
                  cur_slant:=cur_slant+45;
                  i:=0;
                  repeat
                    i:=i+1;
                    seg_len:=max(0.07,min(0.16,0.15*30/scale)); { inches }
                    seg_len:=max(min(seg_len*m_sf,0.16),0.07);
                    if i/4<>int(i/4) then  { 3 rocks 1 fence mark }
                      begin
                        segment(i-1,0.33,x3,y3);  { start  of rock 1/3 tol. }
                        segment(i,0.33,x4,y4);    { end of rock }
                        if x4<>0 then
                          ellipse(x3,y3,x4,y4,0.44 {height/width ellipse_ratio });
                      end
                    else
                      begin
                        seg_len:=seg_len*(i-0.50);
                        segment(1,0.00,x4,y4);
                        if x4<>0 then
                         marker(x4,y4,max(0.06,min(0.11,0.07*40/scale*m_sf/m_scale)),0);
                      end;
                  until x4=0;
                  cur_slant:=cur_slant+45;
                end;
             13:begin { Proposed Pipe or Double Line }
                  seg_len:=dbl_ln_len*at_scale/scale;
                  x3:=x1+sin(a1-pi/2)*seg_len;
                  y3:=y1+cos(a1-pi/2)*seg_len;
                  x4:=x2+sin(a1-pi/2)*seg_len;
                  y4:=y2+cos(a1-pi/2)*seg_len;
                  plot(x1,y1,pu); plot(x3,y3,pd);
                  plot(x4,y4,pd); plot(x2,y2,pd);
                  x3:=x1+sin(a1+pi/2)*seg_len;
                  y3:=y1+cos(a1+pi/2)*seg_len;
                  x4:=x2+sin(a1+pi/2)*seg_len;
                  y4:=y2+cos(a1+pi/2)*seg_len;
                  plot(x4,y4,pd); plot(x3,y3,pd); plot(x1,y1,pd);
                end;
             14:begin {Proposed Pipe}
                end;
          end{case};
        end;
(*      if cur_ln<>9 then     *)
        if (pt_end in [2,3]) and (x2<34.0) and (x2>-34.0) and
            (y2<32.7) and (y2>-32.7) then
          case pt_xhair of
            1:marker(x2,y2,0.07/m_scale,0);
            2:marker(x2,y2,0.0355/m_scale,6);
          end{case};
      cur_marker:=cur_m;
      cur_size:=cur_s;
      cur_ln:=cur_l;
  end;

procedure init_plot;
  begin
    writeln('*** Put Paper in Plotter, Lower Roller Grips *** ');
    writeln('      Press plotter <REMOTE> Key when Ready...');
    plt_select;
    plt_pause;
    plot(0,0,init);
    case page_size of
      'C':begin
            plot(-plt_x/2,-plt_y-0.15,-pu);    { reset origin }
            writeln(out_file,'IW ',-plt_x/2*plt_x_mf*x_scale:5:0,',',
                                   -(plt_y+0.15)*plt_y_mf*y_scale:5:0,',',
                                    plt_x/2*plt_x_mf*x_scale:5:0,',',
                                   -0.15*plt_y_mf*y_scale:5:0,';');
          end;
      'D':plot(-plt_x/2,-plt_y/2,-pu);  { reset origin }
      'Y':plot(-plt_x/2,-plt_y/2,-pu);  { reset origin }
      'Z':plot(-plt_x/2,-plt_y/2,-pu);  { reset origin }
      'O':plot(plt_x*otf_x,plt_y*otf_y,-pu);
      else plot(0,0,-pu);
    end{case};
    case page_size of
           'A':p1_p2_dist:=10.42;
           'B':p1_p2_dist:=16.55;
       'C','D':p1_p2_dist:=36.72;
           'E':p1_p2_dist:=51.94;
       'Y','Z':p1_p2_dist:=24.08;
           'O':p1_p2_dist:=sqrt(sqr(plt_x)+sqr(plt_y))-1.00;
    end{case};
    prform(slow);        { Slow pen speed 16 in./Sec for Better accarcy }
  end;

begin
end.
