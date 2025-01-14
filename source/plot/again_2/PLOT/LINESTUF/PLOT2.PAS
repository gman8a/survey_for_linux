type
  x_y      = record
               rx,ry   : real;
               el      : real;
               plotted : boolean
             end;
var
     page_flag     : boolean;
     ln_file_flag  : boolean;
     ln_flag       : boolean;
     pt_el_flg     : boolean;
     draw_marker   : boolean;
     pt_cnt        : integer;
     led           : integer; { >0 plot ledgent }
     code,p1,p2,p3 : integer; { Line file type code }
     cen_pt,ln_type: integer; { line type }
     pen           : integer;
     lab,lab2      : str80;   { line file single description }
     lab_cnt_c     : integer; { legend counter curves }
     lab_cnt_l     : integer;
     r,len,radius  : real;    { curve length }
     asz1,asz2,asz3: str16;
     a1,a2         : real;    { start and end arc angles from due east }
     low_pt,up_pt  : integer; { lowest point in file to include in this plot }
     any_str       : string[36];
     pt_rec        : point;
     size          : real;  { marker size inches }
     n_p_len       : real;
     e_p_len       : real;
     rot_file      : file of x_y;
     rot_rec       : x_y;
     rot_rec2      : x_y;
     n_ul,e_ul     : real;
     n_lr,e_lr     : real;
     n2_low,n2_up,
     e2_low,e2_up  : real;
     grid          : array[1..30,1..4] of real;
     n_grid,e_grid : real;
     xu,xd,xl,xr,
     yu,yd,yl,yr,
     s,b            :  real;
     rot_ang2       : integer;
     grid_flag      : integer;
     pt_lab         : integer; { >0 to plot point numbers }
     pt_win_file    : file of integer; { pt window file }
     win_pt         : integer;
     o              : integer;  { general use }
     shp_pt_off     : array[0..10] of integer;  { add to shp pt#'s, 10 nested shapes }
     shp_c_scale    : array[0..10] of real;
     shp_m_scale    : array[0..10] of real;
     shp_size_stk   : array[0..10] of real;
     shp_var        : array[1..10] of real;     { shp parameters, 1 per shp}
     shp_page_rot   : array[0..10] of real;     { stack of shp rotation }
     active_shp     : integer;                  { active shapes }
     sf             : array[0..10] of text;
     arrow_ends     : integer;  { 1/0 }
     border         : boolean;

(*   shp_stk_r      : array[1..20] of real;    { for pop & pushing condition }
     shp_stk_i      : array[1..20] of integer;
     shp_stk_p_i,
     shp_stk_p_r    : integer; { FOR POPPING NUMBERS ON AND OFF }
*)
       led_pos : array[1..09,1..2] of real;

procedure get2(pt:integer; var rot_rec:x_y);
  begin
    if pt<=no_pts then
      begin
        seek(rot_file,pt);
        read(rot_file,rot_rec);
      end;
  end;

procedure put2(pt:integer; rot_rec:x_y);
  begin
    seek(rot_file,pt);
    write(rot_file,rot_rec);
  end;

procedure plot_pt_no(p:integer);
  var
    pt_str : string[5];
    x,y:real;
    e,n:real;
    rot_rec:x_y;
  begin
    get2(p,rot_rec);
    if (pt_lab>0) and not (rot_rec.plotted) then
      begin with rot_rec do
        begin
          e:=(rx-e_low2)/scale;
          n:=(ry-n_low2)/scale;
        end;
        x:=e+0.03;
        y:=n-0.12;
        rotate(x,y,e,n,rot_ang);
        rot_rec.plotted:=true;
        put2(p,rot_rec);
        if pt_el_flg then
            begin
              if rot_rec.el<>0 then
                begin
                  str(rot_rec.el:5:1,pt_str);
                  symbol(x,y,5,rot_ang,pt_str,cur_pen);
                end
              else
                begin
                  str(p,pt_str);
                  symbol(x,y,5,rot_ang,pt_str,cur_pen);
                end;
            end
        else begin
               str(p,pt_str);
               symbol(x,y,5,rot_ang,pt_str,cur_pen);
             end;
      end;
  end;

procedure chk_pt_in_window(p1:integer);
  var
    rot_rec:x_y;
  begin
    ln_flag:=false;
    get2(p1,rot_rec);
    with rot_rec do
      if (ry>=n_low2) and (ry<=n_up2) and (rx>=e_low2) and (rx<=e_up2)
        then ln_flag:=true;
  end;

procedure draw_grid;

    procedure  grid_ends;  { figure end point of grid }
      begin
        xl:=e_low2;   yl:=s*e_low2+b;  if (yl>n_up2) or (yl<n_low2) then yl:=0;
        xr:=e_up2;    yr:=s*e_up2+b;   if (yr>n_up2) or (yr<n_low2) then yr:=0;
        xu:=(n_up2-b)/s;  yu:=n_up2;   if (xu>e_up2) or (xu<e_low2) then xu:=0;
        xd:=(n_low2-b)/s; yd:=n_low2;  if (xd>e_up2) or (xd<e_low2) then xd:=0;
        if xd=0 then begin xd:=xl; yd:=yl; end { chose proper intersection }
        else if xu=0 then begin xu:=xl; yu:=yl; end;
        if yd*xd=0 then begin xd:=xr; yd:=yr; end
        else if yu*xu=0 then begin xu:=xr; yu:=yr; end;
      end;

   procedure grid_line;
      begin
        if xr<xl then { swap coordinates }
          begin
            xl:=xd; yl:=yd;
            xd:=xu; yd:=yu;
            xu:=xl; yu:=yl;
          end;
        line((xd-e_low2)/scale,(yd-n_low2)/scale,(xu-e_low2)/scale,(yu-n_low2)/scale,0);
      end;

  begin  { Grid accross page }
    newpen(1); dashs(0);
    rot_ang2:=round(rot_ang*10);
    for k:=1 to 30 do   { northing lines  }
      begin
        case rot_ang2 of
          0,1800:begin
                   xd:=e_low2; yd:=grid[k,1];  if (yd>n_up2) or (yd<n_low2) then yd:=0;
                   xu:=e_up2;  yu:=grid[k,1];  if (yu>n_up2) or (yu<n_low2) then yu:=0;
                 end;
        900,2700:begin  { northing line slope is undefined }
                   xd:=grid[k,2]; yd:=n_low2; if (xd>e_up2) or (xd<e_low2) then xd:=0;
                   xu:=grid[k,2]; yu:=n_up2;  if (xu>e_up2) or (xu<e_low2) then xu:=0;
                 end;
            else begin { find intersection of window and lines }
                   s:=tan(rot_ang*pi/180);
                   b:=grid[k,1]-s*grid[k,2];
                   grid_ends;
                 end;
        end{case};
        if (xd*xu<>0) and (yd*yu<>0) then
          begin
            xl:=sqrt(sqr(xd-grid[k,2])+sqr(yd-grid[k,1]));
            xr:=sqrt(sqr(xu-grid[k,2])+sqr(yu-grid[k,1]));
            grid_line;
            str(n_grid+(k-1)*5*scale:6:0,any_str);
            any_str:='N'+any_str;
            xu:=(xd-e_low2)/scale; yu:=(yd-n_low2)/scale;
            xd:=xu+0.10; yd:=yu+0.03;
            rotate(xd,yd,xu,yu,rot_ang);
            symbol(xd,yd,6,rot_ang,any_str,1);
          end;
      end{northing grid lines};
    for k:=1 to 30 do   { Easting lines }
      begin
        case rot_ang2 of
          0,1800:begin
                   xd:=grid[k,4]; yd:=n_low2; if (xd>e_up2) or (xd<e_low2) then xd:=0;
                   xu:=grid[k,4]; yu:=n_up2;  if (xu>e_up2) or (xu<e_low2) then xu:=0;
                 end;
        900,2700:begin  { easting line slope is undefined }
                   xd:=e_low2; yd:=grid[k,3]; if (yd>n_up2) or (yd<n_low2) then yd:=0;
                   xu:=e_up2;  yu:=grid[k,3]; if (yu>n_up2) or (yu<n_low2) then yu:=0;
                 end;
            else begin { find intersection of window and lines }
                   s:=tan((rot_ang+90)*pi/180);
                   b:=grid[k,3]-s*grid[k,4];
                   grid_ends;
                 end;
        end{case};
        if (xd*xu<>0) and (yd*yu<>0) then
          begin
            xl:=sqrt(sqr(xd-grid[k,4])+sqr(yd-grid[k,3]));
            xr:=sqrt(sqr(xu-grid[k,4])+sqr(yu-grid[k,3]));
            grid_line;
            str(e_grid+(k-1)*5*scale:6:0,any_str);
            any_str:='E'+any_str;
            xu:=(xd-e_low2)/scale; yu:=(yd-n_low2)/scale;
            xd:=xu-0.03; yd:=yu+0.10;
            rotate(xd,yd,xu,yu,rot_ang);
            symbol(xd,yd,6,rot_ang+90,any_str,1);
          end;
      end;
  end;

procedure draw_window;
  begin
    writeln('...Drawing Boarded');
    dashs(0);
    if not border then
      begin
        newpen(1);
        plot(plt_x-1,0,pu); plot(plt_x,0,pd); plot(plt_x,1,pd);
        plot(plt_x,plt_y-1,pu); plot(plt_x,plt_y,pd); plot(plt_x-1,plt_y,pd);
        plot(1,plt_y,pu); plot(0,plt_y,pd); plot(0,plt_y-1,pd);
        plot(0,1,pu); plot(0,0,pd); plot(1,0,pd);
      end
    else
      begin
        newpen(2);
        plot(plt_x,0.00,pu);
        plot(plt_x,plt_y,pd);
        plot(0.00,plt_y,pd);
        plot(0.00,0.00,pd);
        plot(plt_x,0.00,pd);
      end;
    if tag_flag then
      begin
        symbol(0.1,0.05,5,0,when,1); { tag with time/date }
        str(scale:3,any_str);
        any_str:='1 in='+any_str+' ft JOB:'+fn3+lc;
        symbol(0.1,0.17,5,0,any_str,1);   { write filename }
        str(sheet:2,any_str); any_str:='PC-TS - Sheet #'+any_str;
        symbol(0.1,0.32,5,0,any_str,1); { tag with time/date }
      end;
  end;

procedure put_legent;
   var
     flag1:boolean;

   procedure reset_led;
     begin
       reset(led_file);
       for i:=1 to 3 do readln(led_file);
     end;

   begin
      if (ln_file_flag) and (led>0) then
        begin  { put legend on page }
          writeln('...Plotting Legent');
          newpen(1);
          a1:=led_pos[led,1];
          a2:=led_pos[led,2];
          flag1:=false;
          reset_led;
          while (not eof(led_file)) and (not flag1) do
            begin
              readln(led_file,lab);
              if pos('C',lab)>0 then flag1:=true;
            end;
          if flag1 then
            begin
              symbol(a1,a2-1*0.135,6,0,
               'C#   Radius     Delta Ang    Arc Len   CH Len   Chord Bear',1);
              symbol(a1,a2-2*0.135,6,0,
               '===  =======   ===========   =======  =======  ============',1);
              l:=2;
              reset_led;
              while not eof(led_file) do
                begin
                  readln(led_file,lab);
                  if pos('C',lab)>0 then
                    begin l:=l+1; symbol(a1,a2-l*0.135,6,0,lab,1); end;
                end;
            end;
          flag1:=false;
          reset_led;
          while (not eof(led_file)) and (not flag1) do
            begin
              readln(led_file,lab);
              if pos('L',lab)>0 then flag1:=true;
            end;
          if flag1 then
            begin
              symbol(a1+5.25,a2-1*0.135,6,0,'L#  Distance    Bearing',1);
              symbol(a1+5.25,a2-2*0.135,6,0,'=== ========  ============',1);
              l:=2;
              reset_led;
              while not eof(led_file) do
                begin
                  readln(led_file,lab);
                  if pos('L',lab)>0 then
                    begin l:=l+1; symbol(a1+5.25,a2-l*0.135,6,0,lab,1); end;
                end;
            end;
        end{if led flag};
   end;

procedure make_rot_file;
  begin
    writeln;
    writeln('...Making ',rot_ang:3:0,' Deg. Rotation Coordinate File');
    str(rot_ang:3:0,any_str); fn7:=fn7+any_str;
    assign(rot_file,fn7);
    rewrite(rot_file);
    rot_rec.rx:=no_pts; rot_rec.ry:=0;
    write(rot_file,rot_rec);
    rot_rec.plotted:=false;
    for i:=1 to no_pts do
      begin
        get(i,pt_rec);
        with rot_rec do
          begin
            rx:=pt_rec.east;
            ry:=pt_rec.north;
            el:=pt_rec.elev;
            rotate(rx,ry,0,0,rot_ang);
          end;
        write(rot_file,rot_rec);
      end;
  end;

procedure make_led_file;
  begin
    assign(led_file,fn4);
    rewrite(led_file);
    writeln(led_file,fn,pt_rec0.descrip:25,'  ',when);
    writeln(led_file,' #  Rad/Dist   Delta/Bear    Arc Len   CH Len   Chord Bear');
    writeln(led_file,'--- --------  ------------   -------  -------  ------------');
    lab_cnt_l:=0;     { label counter for legend }
    lab_cnt_c:=0;
  end;

procedure rot_grid;
  begin
    { Rotate Grid }
    a1:=int((n_low-30*scale)/5/scale)*5*scale;
    a2:=int((e_low-30*scale)/5/scale)*5*scale;
    n_grid:=a1;
    e_grid:=a2;
    for i:=1 to 30 do
      begin
        grid[i,1]:= a1;
        grid[i,2]:= 0;
        grid[i,3]:= 0;
        grid[i,4]:= a2;
        rotate(grid[i,2],grid[i,1],0,0,rot_ang);
        rotate(grid[i,4],grid[i,3],0,0,rot_ang);
        a1:=a1+5*scale;
        a2:=a2+5*scale;
      end;
  end;

procedure figure_new_window;
  begin
    n_ul:=n_up;
    e_ul:=e_low;
    n_lr:=n_low;
    e_lr:=e_up;
    rotate(e_low,n_low,0,0,rot_ang);  { #1 }
    rotate(e_up,n_up,0,0,rot_ang);
    rotate(e_ul,n_ul,0,0,rot_ang);    { #2 1-2 due north }
    rotate(e_lr,n_lr,0,0,rot_ang);    { #4 1-4 due east }
    n2_low:= minr(n_up, minr(n_lr,minr(n_ul,n_low)));
    n2_up := maxr(n_up, maxr(n_lr,maxr(n_ul,n_low)));
    e2_low:= minr(e_up, minr(e_lr,minr(e_ul,e_low)));
    e2_up := maxr(e_up, maxr(e_lr,maxr(e_ul,e_low)));
    n_low:=n2_low+yt;
    e_low:=e2_low+xt;
    n_up:=n2_up;
    e_up:=e2_up;
  end;

procedure pt_search;
  begin
    write('...Searching for Points');
    assign(pt_win_file,last_drv+':PT.WIN');
    rewrite(pt_win_file);
    write(pt_win_file,i);
    pt_cnt:=0;
    for i:=low_pt to up_pt do
      begin
        get2(i,rot_rec);
        with rot_rec do
          if (ry-n_low>-1) and (ry-n_up<1) and (rx-e_low>-1) and (rx-e_up<1) then
            begin
              get(i,pt_rec);
              with pt_rec do
                begin
                  descrip:=descrip+'   ';
                  for j:=1 to 3 do descrip[j]:=upcase(descrip[j]);
                end;
              if (copy(pt_rec.descrip,1,3)<>'DEL') then
                begin
                  pt_cnt:=pt_cnt+1;
                  write(pt_win_file,i);
                end;
            end;
      end{pt. search};
      writeln('-->Found ',pt_cnt:4,' pts. in window.');
  end;

procedure figure_page_info;
  begin
      n_p_len:=plt_y;
      e_p_len:=plt_x;
      n_pages:=round((n_up-n_low)/scale/n_p_len+0.5);
      e_pages:=round((e_up-e_low)/scale/e_p_len+0.5);
      n_ft:=scale*n_p_len;  { north footage per page }
      e_ft:=scale*e_p_len;
  end;

procedure chk_page_blank;
  begin
    page_flag:=false;
    for k:=1 to pt_cnt do
      if not page_flag then
        begin
          seek(pt_win_file,k); read(pt_win_file,win_pt);
          get2(win_pt,rot_rec);
          with rot_rec do
            if (ry>=n_low2) and (ry<=n_up2) and
               (rx>=e_low2) and (rx<=e_up2) then page_flag:=true;
        end;
  end;

procedure point_plot;
  begin
    if pt_lab=1 then for k:=1 to pt_cnt do
      begin
        seek(pt_win_file,k); read(pt_win_file,win_pt);
        get2(win_pt,rot_rec);
        with rot_rec do
          if (ry>=n_low2) and (ry<=n_up2) and
             (rx>=e_low2) and (rx<=e_up2) then
               begin
                 case pt_xhair of
                   1:marker((rx-e_low2)/scale,(ry-n_low2)/scale,0.07,0);
                   else marker((rx-e_low2)/scale,(ry-n_low2)/scale,0.0355,6);
                 end{case};
                 plot_pt_no(win_pt);
               end;
      end;
    if pt_lab=1 then begin pt_xhair:=-1; pt_lab:=0; end;
  end;

procedure load_shape; {***************************}
  var
    asz1 : str16;
    d    : real;
    any_str:string[10];
    cnt  : integer;
  begin
    while pos(' ',lab)>0 do delete(lab,pos(' ',lab),1);
    if exist(lab+'.SHP') then
      begin
        active_shp:=active_shp+1;
        writeln('...Loading Shape: ',lab:8,' @ Stack#',active_shp);
        assign(sf[active_shp],lab+'.SHP');
        reset(sf[active_shp]);
        shp_pt_off[active_shp]:=no_pts;
        shp_c_scale[active_shp]:=shp_c_scale[active_shp-1]*ln_type/100;
        shp_m_scale[active_shp]:=shp_m_scale[active_shp-1]*ln_type/100;
        shp_size_stk[active_shp]:=shp_size_stk[active_shp-1]*ln_type/100;
        m_scale:=shp_m_scale[active_shp];
        if code=19 then
          shp_page_rot[active_shp]:=cen_pt+shp_page_rot[active_shp-1]
        else
          begin
             pt_to_pt(p2,cen_pt,d,asz1);
             d:=(pi/2-asz_rad(asz1))*180/pi;
             adj_ang(d);
            shp_page_rot[active_shp]:=d;
          end;
        shp_var[active_shp]:=pen;
        get(p1,pt_rec);                  { where pt }
        with pt_rec do
          begin xd:=east; yd:=north; end;
        init_pt_rec(pt_rec);
        readln(sf[active_shp],xl,yl);    { shp about pt }
        xu:=xd-xl; yu:=yd-yl;            { translation offset }
        xr:=xl; yr:=yl;                  { local rotate about pt }
        a2:=shp_page_rot[active_shp];
        cnt:=0;
        repeat { load in shape points }
          ptpt(xr,yr,xl,yl,r,asz1);          { handle size }
          a1:=asz_rad(asz1);
          xl:=xu+xr+sin(a1)*r*shp_size_stk[active_shp];   { translate and size factor }
          yl:=yu+yr+cos(a1)*r*shp_size_stk[active_shp];
          rotate(xl,yl,xd,yd,a2);            { rotate into postion };
          cnt:=cnt+1;
          str(cnt:4,any_str);
          with pt_rec do begin east:=xl; north:=yl; descrip:=fn+' pt#'+any_str; end;
          if code=19 then rotate(xl,yl,xd,yd,-rot_ang);
          rotate(xl,yl,0,0,rot_ang);
          with rot_rec do begin rx:=xl; ry:=yl; end;
          put(no_pts+1,pt_rec);
          put2(no_pts,rot_rec);
          readln(sf[active_shp],xl,yl);
        until (xl=0) and (yl=0);
      end;
  end;

procedure set_variables;
 var err,i:integer;
  begin
    if p1>0 then
      begin
        at_scale:=p1; { auto char sizing }
        m_sf:=shp_c_scale[active_shp]*at_scale/scale;
        pt_xhair:=p2;
        arrow_ends:=cen_pt;
        dashs(ln_type);
        newpen(pen);
        while copy(lab,1,1)=' ' do delete(lab,1,1);
        val(lab,i,err); if i=0 then i:=slow;
        if err=0 then prform(i) else prform(fast);
      end
    else
      case p1 of
        0:begin
            led_pos[9,1]:=p2/100; led_pos[9,2]:=cen_pt/100;
            if ln_type=0 then tag_flag:=false;
            if pen>0 then prform(pen);
          end;
       -1:begin
            dbl_ln_len:=p2/100;
            perp_ang:=cen_pt;
            writeln(out_file,'S(F',ln_type:1,',H',pen:1,')_');
          end;
      end{case};
  end;

procedure arc;

  procedure plot_end_pt(p1:integer);
   var rot_rec : x_y;
     begin
       get2(p1,rot_rec);
       if (pt_xhair>0) and not (rot_rec.plotted) then with rot_rec do
         begin
           case pt_xhair of
             1:marker((rx-e_low2)/scale,(ry-n_low2)/scale,0.07/m_scale,0);
             2:marker((rx-e_low2)/scale,(ry-n_low2)/scale,0.0355/m_scale,6);
           end{case};
         end;
         if pt_lab=2 then plot_pt_no(p1);
     end;

  begin { figure start angle in degrees from due east direction }
    pt_to_pt(cen_pt,p1,r,asz1);
    a1:=(pi/2-asz_rad(asz1))*180/pi;
    adj_ang(a1);
    pt_to_pt(cen_pt,p2,r,asz2);
    a2:=(pi/2-asz_rad(asz2))*180/pi;
    adj_ang(a2);
    if a2>a1 then a2:=a2-360; { circle direction }
    len:=asz_rad(asz2)-asz_rad(asz1);
    while len<0 do len:=len+2*pi;
    asz3:=rad_asz(len);    { delta angle }
    len:=asz_rad(asz3)*r;  { length of curve }
    radius:=r;             { radius }
    get2(cen_pt,rot_rec);
    if ln_type<>9 then with rot_rec do
      circle((rx-e_low2)/scale,(ry-n_low2)/scale,r/scale,a1+rot_ang,a2+rot_ang);
    plot_end_pt(cen_pt);
    plot_end_pt(p1);
    plot_end_pt(p2);
    with pt_rec do
      case t_code of
    'T','O','I','P':begin
                      get(cen_pt,pt_rec);
                      distance:=radius+0.03*scale;
                      if t_code in ['I','T'] then distance:=radius-0.135*scale;
                      aszmith:=asz_rad(asz1)+asz_rad(asz3)/2-0.088*scale/radius;
                      if t_code in['O','I'] then
                        aszmith:=asz_rad(asz1)+asz_rad(asz3)/2-0.264*scale/radius;
                      from_pt:=cen_pt;
                      code:=0;
                    end;
                'D':begin
                     get(p1,pt_rec);
                     distance:=radius/2-0.45*scale;
                     aszmith:=asz_rad(asz1)+arctan(0.135/(distance/scale));
                     from_pt:=cen_pt;
                     code:=0;
                   end;
      end{case};
    calculate(pt_rec); with pt_rec do rotate(east,north,0,0,rot_ang);
    if t_code in ['P','I','O','T'] then pt_to_pt(p1,p2,r,asz1);
    a1:=(pi/2-asz_rad(asz1))*180/pi;
    adj_ang(a1);
    with pt_rec do
      case  t_code of
    'T','P':begin
              lab_cnt_c:=lab_cnt_c+1;
              str(lab_cnt_c,any_str); any_str:='C'+any_str;
              symbol((east-e_low2)/scale,(north-n_low2)/scale,7,a1+rot_ang,any_str,pen);
              asz1:=rad_bear(asz_rad(asz1));
              delete(asz1,2,1); delete(asz1,12,1);
              writeln(led_file,any_str:3,radius:9:3,'  ',asz3,len:10:3,r:9:3,'  ',asz1);
            end;
        'D':begin { draw arc data }
              str(radius:8:3,any_str); any_str:='R='+any_str;
              symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str,pen);
              aszmith:=asz_rad(asz1)-arctan(0.03/(distance/scale));
              calculate(pt_rec); with pt_rec do rotate(east,north,0,0,rot_ang);
              any_str:='D='+copy(asz3,1,11);
              symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str,pen);
              aszmith:=asz_rad(asz1)-arctan(0.165/(distance/scale));
              calculate(pt_rec); with pt_rec do rotate(east,north,0,0,rot_ang);
              str(len:8:3,any_str); any_str:='L='+any_str;
              symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str,pen);
            end;
    'O','I':begin
              str(len:6:2,any_str);
              symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str,pen);
            end;
      end{case};
    end{arc};

procedure arrow(xu,yu,xl,yl:real; arrow_type:integer);
 var
    s,s1,s2,r,r2,b,b2:real;
    x,y,a1 : real;
    asz1: str16;

  begin  { draw arrow ends }
    cur_l:=cur_ln;
    dashs(0);
    s1:=0.025*shp_size_stk[active_shp];
    s2:=0.090*shp_size_stk[active_shp];
    ptpt(xu,yu,xl,yl,r,asz1); { figure arrow }
    a1:=asz_rad(asz1);
    if (arrow_ends>0) and (arrow_type>0) then
      begin { Dim Ends }
        r2:=sqrt(sqr(s2/1.5)+sqr(r)); { line ends }
        b2:=arctan(s2/1.5/r);
        x:=xu+sin(a1+b2)*r2;
        y:=yu+cos(a1+b2)*r2;
        xr:=xu+sin(a1-b2)*r2;
        yr:=yu+cos(a1-b2)*r2;
        line(x,y,xr,yr,0);
      end;
    case arrow_type of
     1:begin { arrow }
        s:=arctan(s1/(r-s2));
        b:=sqrt(sqr(s1)+sqr(r-s2));
        xr:=xu+sin(a1+s)*b;
        yr:=yu+cos(a1+s)*b;
        xu:=xu+sin(a1-s)*b;
        yu:=yu+cos(a1-s)*b;
        line(xl,yl,xu,yu,0);
        line(xu,yu,xr,yr,0);
        line(xr,yr,xl,yl,0);
      end;
     2:begin  {slash}
        s1:=s1*1.3;
        s:=arctan(s1/(r-s1));
        b:=sqrt(sqr(s1)+sqr(r-s1));
        xr:=xu+sin(a1+s)*b;
        yr:=yu+cos(a1+s)*b;
        b:=sqrt(sqr(s1)+sqr(r+s1));
        xu:=xu+sin(a1-s)*b;
        yu:=yu+cos(a1-s)*b;
        line(xr,yr,xu,yu,0);
      end;
    end{case};
    dashs(cur_l);
  end;
