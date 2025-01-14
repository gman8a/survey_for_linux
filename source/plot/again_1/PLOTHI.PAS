unit plothi;
interface

uses plot1,basics4,crt;

var
      large     : boolean;
      mult_pen_flag : boolean;

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
   curve_arr   : array[1..80,1..2] of real; { for general polly line curves }

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
     c_scale  : real;  { char scale factor .67 = 30 Scale }
     m_scale  : real;  { marker scale }

const
     pu       : integer =3;   { pen up }
     pd       : integer =2;   { pen down }
     init     : integer =0;   { initialize to power up state }
     x_scale  : real = 1.00;
     y_scale  : real = 1.00;

     fast     : integer =0;  { plotter Pen speed 4 inches/sec}
     slow     : integer =1;
     plt_y = 07.40;          { inches , north page length }
     plt_x = 9.75;{10.40;}
     plt_x_mf = 254.0;
     plt_y_mf = 254.0;

procedure adj_ang(var angle:real);
procedure plt_deselect;
procedure plt_select;
procedure plt_reset;
procedure prform(i:integer);
procedure plot(x,y:real; code:integer); { x,y inches }
procedure circle(x,y,r,a1,a2 :real);   { x,y=center pt.,  a1-start a2-end angles from due east }
procedure set_line(i:integer; d:real);
procedure dashs(i:integer); { pass the line type }
procedure char(i,j: REAL; code:integer);
procedure setchr(ch,cs,slant:real;  emphasis:integer);
procedure newpen(i:integer);
procedure symbol(x,y:real; char_type:integer;
                    angle:real; p_str :str80; pen:integer);
procedure poly_curve(np:integer); { np = # coordinate pairs in curve_arr }
procedure ellipse(x3,y3,x4,y4,ellipse_ratio:real);
procedure mark_shape(x,y,size :real; m_type:integer);  { x-y center, size-inches }
procedure marker(x,y,size :real; m_type :integer);  { size-inches }
procedure line(x1,y1,x2,y2:real; pt_end:integer);
procedure init_plot;

implementation

procedure adj_ang(var angle:real);
  begin
    while angle>360 do angle:=angle-360;
    while angle<000 do angle:=angle+360;
  end;

procedure plt_deselect;
  begin
    writeln(out_file,'HO');  {  home pen & deselect then plotter }
  end;

procedure plt_select;
  begin
  end;

procedure plt_reset;
  begin
    plt_deselect;
    writeln(out_file,'DF');
    writeln(out_file,'CI');
    delay(1000);
  end;

procedure prform(i:integer);
  begin
      if i>1 then i:=1;
      writeln(out_file,'VS ',i:1);          { Pen velocity 0 or 1 }
  end;

procedure plot(x,y:real; code:integer); { x,y inches }
  begin
    x:=x*plt_x_mf*x_scale;   { change inches to plotter units }
    y:=y*plt_y_mf*y_scale;   { plotter set for .001 inches per movement unit }
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
          plt_reset;
          c_scale:=1;
          m_scale:=1;
      end;
    if (abs(cur_x-x)>1.0) or (abs(cur_y-y)>1.0) or (abs(code)=2) then
    case code of
       0:writeln(out_file,'IN');               { INITialize plotter }
    -3,3:writeln(out_file,'MA ',x:4:0,' ',y:4:0); { Pen UP  }
    -2,2:writeln(out_file,'DA ',x:4:0,' ',y:4:0); { PEN DOWN }
    end{case};
    if code<0 then writeln(out_file,'OR');             { Set new origin }
    cur_x:=x;
    cur_y:=y;
  end;

procedure circle(x,y,r,a1,a2 :real);   { x,y=center pt.,  a1-start a2-end angles from due east }
var
  x1,y1,r1 :integer;
  begin
    x1:=round(x*plt_x_mf*x_scale);
    y1:=round(y*plt_y_mf*y_scale);
    r1:=round(r*plt_x_mf*x_scale);
    writeln(out_file,'CA ',x1:4,' ',y1:4,' ',r1:4,' ',round(a1*10):4,' ',round(a2*10):4);
    cur_x:=-100;
    cur_y:=-100;
  end;

procedure set_line(i:integer; d:real);
  begin
    writeln(out_file,'LT ',i:3);             { line type }
    writeln(out_file,'LP ',round(d*254):3);  { line segment repeat length }
  end;

procedure dashs(i:integer); { pass the line type }
  begin
    if i<>cur_ln then
      case i of
        0:set_line(0,1.00);   { solid line }
        1:set_line(1,0.30);   { Dashed line 1 }
        2:set_line(7,0.30);   { property line }
        3:set_line(5,0.30);   { Center Line }
        4:set_line(3,0.50);   { Dotted Line }
        5:set_line(8,0.30);   { Center Line 2 }
        6:set_line(2,0.10);   { Dotted Line 2 }
        7:set_line(6,0.30);   { Dashed line 2 }
        8:set_line(4,0.30);   { Dashed line 3 }
      end{case};
    cur_ln:=i;
  end;

procedure char(i,j: REAL; code:integer);

VAR
   CH,CS,SL   :INTEGER;
 CONST
   af : real = 0.01745329;  { mult. factor to convert degrees to radians }

  begin
    case code of
      0:writeln(out_file,'RC');                   { reset all character attributes }
      1:BEGIN
          CH:=ROUND(I*C_SCALE*254);
          CS:=ROUND(j*C_SCALE*254);
          writeln(out_file,'SI ',CH:5,' ',CS:5);  { character height and spaceing }
        END;
      2:writeln(out_file,'VO ',ROUND(254*I):6);   { Set vertical offset }
      3:Writeln(out_file,'DI ',ROUND(010*i):6);   { Line direction }
      4:begin
          sl:=round(sin(i*af)/cos(i*af)*256);
          writeln(out_file,'SL ',SL:4);           { char. slant degrees}
        end;
      5:writeln(out_file,'EM ',trunc(I):1);       { Set Emphasis mode i=0-3 }
    end;
  end;

procedure setchr(ch,cs,slant:real;  emphasis:integer);
 { char height, char spacing, slant angle, emp. mode 0-3 }
  begin
    char(slant,0,4);
    if cs=0 then cs:=6/7*ch;
    char(ch,cs,1);
    char(emphasis mod 4,0,5);
    cur_cs:=cs;
    cur_ch:=ch;
  end;

procedure newpen(i:integer);
  begin
    i:=i mod 5;if i=0 then i:=1;
    if cur_pen<>i then writeln(out_file,'SP ',i:1);   { Select pen # 1 -4 }
    cur_pen:=i;
  end;

procedure symbol(x,y:real; char_type:integer;
               angle:real; p_str :str80; pen:integer);
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
          6:setchr(0.10,0.085,0,0);
          7:setchr(0.10,0.085,20,0);
        end{case};
        cur_chr:=char_type;
      end;
    if (angle>135) and (angle<315) then
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
    writeln(out_file,'LA',p_str:length(p_str));
    cur_x:=-100;
    cur_y:=-100;
  end;

procedure poly_curve(np:integer); { np = # coordinate pairs in curve_arr }
  { the first point is so that the tangent around the point 2 is as desired }
  var
    i  : integer;
  begin
(*    plot(curve_arr[1,1],curve_arr[1,2],pu);  { set for 1 tangent line } *)
    for i:=1 to np do
      begin
        curve_arr[i,1]:=curve_arr[i,1]*plt_x_mf*x_scale;   { change inches to plotter units }
        curve_arr[i,2]:=curve_arr[i,2]*plt_y_mf*y_scale;   { plotter set for .001 inches per movement unit }
      end;
    if (curve_arr[1,1]=curve_arr[np,1]) and (curve_arr[1,2]=curve_arr[np,2])
      then begin write(out_file,'VA 1'); np:=np-1; end
      else write(out_file,'VA 0');
    for i:= 1 to np do write(out_file,',',curve_arr[i,1]:5:0,',',curve_arr[i,2]:5:0);
    writeln(out_file);
  end;

procedure ellipse(x3,y3,x4,y4,ellipse_ratio:real);
 var
   a1,a2,d2  : real;
   asz       : str16;

  begin
    ptpt(x3,y3,x4,y4,d2,asz);
    a1:=asz_rad(asz);
    a2:=arctan(ellipse_ratio);            { angle to ellipse points }
    d2:=d2/2*sqrt(1+sqr(ellipse_ratio));  { distance to height points }
    curve_arr[1,1]:=x3+sin(a1+a2)*d2;
    curve_arr[1,2]:=y3+cos(a1+a2)*d2;
    curve_arr[2,1]:=x3;
    curve_arr[2,2]:=y3;
    curve_arr[3,1]:=x3+sin(a1-a2)*d2;
    curve_arr[3,2]:=y3+cos(a1-a2)*d2;
    curve_arr[4,1]:=x4;
    curve_arr[4,2]:=y4;
    curve_arr[5,1]:=curve_arr[1,1];
    curve_arr[5,2]:=curve_arr[1,2];
(*    curve_arr[6,1]:=x3;
    curve_arr[6,2]:=y3;
    curve_arr[7,1]:=curve_arr[3,1];
    curve_arr[7,2]:=curve_arr[3,2];
*)
    poly_curve(5);

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
      2:begin  {square}
          x:=x2-s; y:=y2-s; plot_rot;
          x:=x2+s; y:=y2-s; plot_rot;
          x:=x2+s; y:=y2+s; plot_rot;
          x:=x2-s; y:=y2+s; plot_rot;
          x:=x2-s; y:=y2-s; plot_rot;
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
       0,2,4,6,7..99:mark_shape(x,y,size,m_type);
       1,3,5:begin
               plot(x,y,pu);
               size:=size*plt_y_mf/4;
(*               writeln(out_file,'M(S',size:4:0,')',m_type:1);    *)
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
             1:marker(x1,y1,0.07,0); { x-hair }
             2:marker(x1,y1,0.0355,6); { small circle }
           end{case};
    if cur_ln<9 then { use standard plotter line }
       begin plot(x1,y1,pu); plot(x2,y2,pd); end
    else if cur_ln>9 then  { draw our special lines }
        begin
          ptpt(x1,y1,x2,y2,ln_len,asz);
          a1:=asz_rad(asz);
          dashs(0); { set solid Line }
          case cur_l of
             10:begin  {stone wall}
                  seg_len:=maxr(0.07,minr(0.16,0.15*30/scale)); { inches }
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
                  cur_slant:=cur_slant+45;
                  i:=0;
                  x3:=x1; y3:=y1; {start of fence}
                  repeat
                    seg_len:=i*0.38+0.30; segment(1,0.0,x4,y4); {fence end}
                    plot(x3,y3,pu);
                    if x4<>0 then plot(x4,y4,pd) else plot(x2,y2,pd);
                    seg_len:=i*0.38+0.34; segment(1,0.0,x4,y4);
                    if x4<>0 then marker(x4,y4,maxr(0.06,minr(0.14,0.07*40/scale)),0);
                    i:=i+1;
                    seg_len:=i*0.38; segment(1,0.0,x3,y3); { new start }
                  until x3*x4=0;
                  cur_slant:=cur_slant-45;
                end;
             12:begin {Stone Wall & Fence}
                  cur_slant:=cur_slant+45;
                  i:=0;
                  repeat
                    i:=i+1;
                    if i/4<>int(i/4) then  { 3 rocks 1 fence mark }
                      begin
                        seg_len:=maxr(0.07,minr(0.16,0.15*30/scale)); { inches }
                        segment(i-1,0.33,x3,y3);  { start  of rock 1/3 tol. }
                        segment(i,0.33,x4,y4);    { end of rock }
                        if x4<>0 then
                          ellipse(x3,y3,x4,y4,0.44 {height/width ellipse_ratio });
                      end
                    else
                      begin
                        seg_len:=maxr(0.07,minr(0.16,(0.15*30/scale)))*(i-0.50); segment(1,0.00,x4,y4);
                        if x4<>0 then marker(x4,y4,maxr(0.06,0.08*40/scale),0);
                      end;
                  until x4=0;
                  cur_slant:=cur_slant+45;
                end;
             13:begin {Exisiting Culvert}
                end;
             14:begin {Proposed Pipe}
                end;
          end{case};
        end;
(*      if cur_ln<>9 then     *)
        if (pt_end in [2,3]) and (x2<34.0) and (x2>-34.0) and
            (y2<32.7) and (y2>-32.7) then
          case pt_xhair of
            1:marker(x2,y2,0.07,0);
            2:marker(x2,y2,0.0355,6);
          end{case};
      cur_marker:=cur_m;
      cur_size:=cur_s;
      cur_ln:=cur_l;
  end;

procedure init_plot;
  begin
    writeln('*** Put Paper in Plotter, Lower Roller Grips *** ');
    quest2(0,0,'Press <SPACE BAR> when Ready...',[' '],false); writeln;
    plot(0,0,init);
    plot(0.10,0.10,-pu); { reset origin }
    prform(slow);        { Slow pen speed 16 in./Sec for Better accarcy }
  end;


end.