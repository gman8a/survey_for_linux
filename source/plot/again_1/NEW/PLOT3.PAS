procedure pop_shp_file;
  begin
    close(sf[active_shp]);
    set_no_pts(shp_pt_off[active_shp]);
    active_shp:=active_shp-1;
    m_scale:=shp_m_scale[active_shp];
  end;

begin  {************* B E G I N   P L O T   P R O C.   *************}
start_plot;
if ln_file_flag then
  begin
    writeln;
    quest2(0,0,'Plot Point [N]umbers or Point [E]levation ? ',['N','E'],false);
    if response='E' then pt_el_flg:=true else pt_el_flg:=false;
    adj_ang(rot_ang);
    make_rot_file;

    make_led_file;
writeln('here1');
    rot_grid;
writeln('here2');
    figure_new_window;
    pt_search;
    figure_page_info;
      for i:=1 to n_pages do
        begin
          n_low2:=n_low+(i-1)*n_ft;
          n_up2 :=n_low2+n_ft;
          for j:=1 to e_pages do
            begin
              e_low2:=e_low+(j-1)*e_ft;
              e_up2 :=e_low2+e_ft;
              chk_page_blank;
              sheet:=(i-1)*e_pages+j;
              if page_flag then
                begin
                  write('Plot Sheet #',sheet:2);
                  quest2(0,0,' (Y/N) ? ',['Y','N'],false); writeln;
                  if response='N' then page_flag:=false;
                end;
              if page_flag then
                begin
                  init_plot;
                  newpen(1);
                  cur_slant:=rot_ang;
                  writeln('...Plotting Sheet #',sheet:2);
                  reset(sf[0]); (* readln(sf[0]); *)
                  readln(sf[0],code,scale,rot_ang,xt,yt,grid_flag,pt_Xhair,pt_lab,led);
                  point_plot;
                  while (not eof(sf[0])) or (active_shp>0) do
                    begin
                      while (active_shp>0) and (eof(sf[active_shp])) do pop_shp_file;
                      code:=99;
                      if (active_shp=0) and (eof(sf[0])) then
                        writeln('*** End of File ***')
                      else
                        begin code:=99;
                         {$I-}
                         readln(sf[active_shp],code,p1,p2,cen_pt,ln_type,pen,lab);
                         {$I+}
                        end;
                      if IOResult>0 then
                        begin
                          code:=99;
                          readln(sf[active_shp]);
                          write('FILE READ ERROR (Ignored)==> ');
                        end;
                      if code=86 then do_it:=false;
                      if code=87 then do_it:=true;
                      if (not do_it) or (code=87) then code:=99;
                      writeln(code:3,p1:5,p2:5,cen_pt:5,ln_type:5,pen:5,'  ',lab);
                      if code in [0,1,2,4..13,18,19,20] then
                           begin
                             if p1>0 then p1:=p1+shp_pt_off[active_shp];
                             if p2>0 then p2:=p2+shp_pt_off[active_shp];
                           end;
                      if code in [2,6,7,8,13,18,20] then
                        begin
                          if cen_pt>0 then
                            cen_pt:=cen_pt+shp_pt_off[active_shp];
                          if code in [6,7,8,20] then
                            begin
                              if (ln_type>0) and (code<>8) then
                                ln_type:=ln_type+shp_pt_off[active_shp];
                              if pen>0 then
                                pen:=pen+shp_pt_off[active_shp];
                            end;
                        end;
                      if (code in [3,14]) and (p1>0) then
                        p1:=p1+shp_pt_off[active_shp];
                      if code=16 then set_variables;
                      if code in [18,19] then load_shape;
                      if not (code in [16,17,18,19,99]) then
                        begin
                          if length(lab)>1 then t_code:=upcase(lab[2]) else t_code:=' ';
                          t_code2:=t_code;
                          if p1>0 then chk_pt_in_window(p1);
                          if (not ln_flag) and (p2>0) then chk_pt_in_window(p2);
                          k:=p1+1;
                          if code in [4,5,10] then
                            while (not ln_flag) and (k<=p2) do
                              begin
                                chk_pt_in_window(k);
                                k:=k+1;
                              end;
                          if code in [3,6,7,8,9,13,14,20] then ln_flag:=true;
                          if code in [0,1,2,4,5,10,11] then
                            begin newpen(pen); dashs(ln_type); end;
                        end
                      else ln_flag:=false;
                      if ln_flag then
                        begin
                          case code of
                          0,1:begin if cen_pt>0 then draw_marker:=true
                                    else draw_marker:=false;
                                    pt_pt_line(p1,p2);
                              end;
                            2:arc;
                            3:if p1=0 then
                                begin
                                  cur_size:=0.04+0.02*cen_pt;
                                  cur_marker:=ln_type;
                                  cur_slant:=p2;
                                  perp_ang:=pen;
                                end
                              else
                              begin
                                size:=0.04+0.02*cen_pt;
                                if pt_xhair<>-1 then pt_xhair:=pen;
                                lab:=''+lab;
                                get2(p1,rot_rec);
                                p2:=p2+round(shp_page_rot[active_shp]);
                                a2:=maxr(0.070,0.105*(at_scale/scale)*shp_c_scale[active_shp]);
                                setchr(a2,0,0,0);
                                with rot_rec do begin
                                  symbol((rx-e_low2)/scale,(ry-n_low2)/scale,0,p2+rot_ang,lab,cur_pen);
                                  marker((rx-e_low2)/scale,(ry-n_low2)/scale,size,ln_type);
                                end;
                              end{if/CASE#3};
                       4,5:begin  { draw consecutive lines }
                             if cen_pt<>0 then draw_marker:=true
                             else draw_marker:=false;
                             repeat { plot lines }
                              if p2>p1 then
                                begin pt_pt_line(p1,p1+1); p1:=p1+1; end
                              else
                                begin pt_pt_line(p1,p1-1); p1:=p1-1; end;
                             until p1=p2;
                           end{case#4,5};
                       6,7:begin { draw 4 multi-lines with last ln_type & Pen }
                             pt_pt_line(p1,p2);
                             if cen_pt<>0 then
                               begin
                                 pt_pt_line(p2,cen_pt);
                                 if ln_type<>0 then
                                   begin
                                     pt_pt_line(cen_pt,ln_type);
                                     if pen<>0 then pt_pt_line(ln_type,pen);
                                   end;
                               end;
                           end{case#6,7};
                       8,9:begin
                             for o:=1 to length(lab) do lab[o]:=upcase(lab[o]);
                             if code=8 then
                               begin
                                 pt_to_pt(p2,Cen_pt,r,asz1);
                                 a1:=(pi/2-asz_rad(asz1))*180/pi+rot_ang;
                                 adj_ang(a1);
                               end
                             else a1:=cen_pt+shp_page_rot[active_shp];
                             a2:=maxr(0.070,ln_type/100*(at_scale/scale)*shp_c_scale[active_shp]);
                             if pos('I',lab) in [2,3,4] then setchr(a2,0,20,0)
                             else setchr(a2,0,0,0);
                             cur_l:=cur_ln;
                             dashs(0);
                             o:=0;
                             get2(p1,rot_rec);
                             with rot_rec do
                               begin
                                 xd:=(rx-e_low2)/scale;
                                 yd:=(ry-n_low2)/scale;
                               end;
                             k:=0;
                             repeat
                               readln(sf[active_shp],lab2);
                               writeln(lab2);
                               p3:=pos('//',lab2);
                               if p3>0 then delete(lab2,p3,2);
                               if o<length(lab2) then o:=length(lab2);
                               yu:=yd;
                               xu:=xd+k*(1.32*a2);
                               rotate(xu,yu,xd,yd,a1-90);
                               symbol(xu,yu,0,a1,lab2,cur_pen);
                               if (k=0) and (pos('U',lab) in [2,3,4]) then {underline}
                                 begin
                                   yu:=yd;
                                   xu:=xd+0.32/2*a2;
                                   rotate(xu,yu,xd,yd,a1-90);
                                   yl:=yd;
                                   xl:=xd+sqrt(sqr(0.32/2*a2)+sqr(o*a2*6/7));
                                   rotate(xl,yl,xd,yd,a1-arctan(0.32/2*7/o/6)*180/pi);
                                   line(xu,yu,xl,yl,0);
                                 end;
                               if (k=0) and ((pos('S',lab) in [2,3,4]) or
                                             (pos('E',lab) in [2,3,4])) and
                                  ( ((code=8) and (pen>0)) or
                                    ((code=9) and ( p2>0)) ) then
                                 begin
                                   yu:=yd+0.50*a2;
                                   if t_code='S' then xu:=xd-0.25*a2
                                   else xu:=xd+o*a2*6/7+0.25*a2;
                                   rotate(xu,yu,xd,yd,a1);
                                   if code=9 then get2(p2,rot_rec)
                                   else get2(pen,rot_rec);
                                   with rot_rec do
                                     begin
                                       xl:=(rx-e_low2)/scale;
                                       yl:=(ry-n_low2)/scale;
                                     end;
                                   line(xu,yu,xl,yl,0);
                                   arrow(xu,yu,xl,yl,1); { pass line ends }
                                 end;
                               k:=k+1;
                             until (p3>0);
                             if pos('B',lab) in [2,3,4] then {draw box around words}
                               begin
                                 yu:=yd+1.5*a2;
                                 xu:=xd-0.5*a2;
                                 rotate(xu,yu,xd,yd,a1);
                                 yl:=yd+1.5*a2;
                                 xl:=xd+o*a2*6/7+0.5*a2;
                                 rotate(xl,yl,xd,yd,a1);
                                 yr:=yd-(k-1)*1.32*a2-0.5*a2;
                                 xr:=xd-0.5*a2;
                                 rotate(xr,yr,xd,yd,a1);
                                 s:=yd-(k-1)*1.32*a2-0.5*a2;
                                 b:=xd+o*a2*6/7+0.5*a2;
                                 rotate(b,s,xd,yd,a1);
                                 line(xu,yu,xl,yl,0);
                                 line(xl,yl,b,s,0);
                                 line(b,s,xr,yr,0);
                                 line(xr,yr,xu,yu,0);
                               end;
                             dashs(cur_l);
                           end{case#8};
                        10:begin {Polly Line}
                             p3:=2;
                             repeat { plot lines }
                               get2(p1,rot_rec);
                               curve_arr[p3,1]:=(rot_rec.rx-e_low2)/scale;
                               curve_arr[p3,2]:=(rot_rec.ry-n_low2)/scale;
                               p3:=p3+1;
                               p1:=p1+1;
                             until p1>p2;
                             curve_arr[p3,1]:=curve_arr[p3-1,1];
                             curve_arr[p3,2]:=curve_arr[p3-1,2];
                             curve_arr[1,1]:=curve_arr[2,1];
                             curve_arr[1,2]:=curve_arr[2,2];
                             poly_curve(p3);
                           end{case#10};
                        11:begin {Oval}
                             get2(p1,rot_rec);
                             get2(p2,rot_rec2);
                             ellipse((rot_rec.rx-e_low2)/scale,(rot_rec.ry-n_low2)/scale,
                                     (rot_rec2.rx-e_low2)/scale,(rot_rec2.ry-n_low2)/scale,
                                      cen_pt/100);
                           end{case#11};
                        12:begin { dimension lines }
                             get2(p1,rot_rec);
                              with rot_rec do
                                begin
                                  xl:=(rx-e_low2)/scale;
                                  yl:=(ry-n_low2)/scale;
                                end;
                              get2(p2,rot_rec);
                              with rot_rec do
                                begin
                                  xu:=(rx-e_low2)/scale;
                                  yu:=(ry-n_low2)/scale;
                                end;
                             while lab[1]=' ' do delete(lab,1,1);
                             while lab[length(lab)]=' ' do delete(lab,length(lab),1);
                             a1:=maxr(0.050,ln_type/100*(at_scale/scale)*shp_c_scale[active_shp]);
                             a2:=length(lab)*a1*6/7; { character length }
                             ptpt(xl,yl,xu,yu,r,asz1);
                             s:=asz_rad(asz1);
                             cur_l:=cur_ln;
                             setchr(a1,0,0,0);
                             dashs(0);
                             line(xu,yu,xl,yl,0);
                             case pen of
                              0,1,4,7..99
                                   :begin
                                      if pen=4 then pen:=2;
                                      arrow(xu,yu,xl,yl,pen);
                                      arrow(xl,yl,xu,yu,pen);
                                    end;
                                2,5:begin
                                      if pen=2 then pen:=1 else pen:=2;
                                      arrow(xu,yu,xl,yl,pen);
                                    end;
                                3,6:begin
                                      if pen=3 then pen:=1 else pen:=2;
                                      arrow(xl,yl,xu,yu,pen);
                                    end;
                             end{case};
                             case cen_pt of        { dimension type }
                                1:begin r:=r/2-a2/2; b:=pi/2-s; end;
                                2:begin r:=r/2+a1/2; b:=pi-s; end;
                             end{case};
                             a2:=s-arctan(0.04/r);
                             r:=sqrt(sqr(r)+sqr(0.04));
                             xu:=xl+sin(a2)*r;
                             yu:=yl+cos(a2)*r;
                             symbol(xu,yu,0,b*180/pi,lab,cur_pen);
                             dashs(cur_l);
                           end{case#12};
                     13,14:begin {rectangle}
                             get2(p1,rot_rec);
                             with rot_rec do
                               begin xd:=(rx-e_low2)/scale;
                                     yd:=(ry-n_low2)/scale;
                               end;
                             if code=13 then
                               begin  { orientation }
                                 pt_to_pt(p2,cen_pt,r,asz1);
                                 r:=(pi/2-asz_rad(asz1))*180/pi+rot_ang;
                                 adj_ang(r);
                               end
                             else r:=cen_pt+shp_page_rot[active_shp];
                             a1:=ln_type/100*at_scale/scale*shp_size_stk[active_shp];
                             a2:=pen/100*at_scale/scale*shp_size_stk[active_shp];
                             xu:=xd+a1; yu:=yd; rotate(xu,yu,xd,yd,r);
                             xl:=xd+a2; yl:=yd; rotate(xl,yl,xd,yd,r+90);
                             s:=arctan(a2/a1)*180/pi; { angle to diagnol pt }
                             a2:=sqrt(sqr(a2)+sqr(a1));
                             xr:=xd+a2; yr:=yd; rotate(xr,yr,xd,yd,r+s);
                             if pos('1',lab)=0 then line(xd,yd,xu,yu,0);
                             if pos('2',lab)=0 then line(xu,yu,xr,yr,0);
                             if pos('3',lab)=0 then line(xr,yr,xl,yl,0);
                             if pos('4',lab)=0 then line(xl,yl,xd,yd,0);
                           end;
                        20:begin {multi poly line}
                             p3:=polly_cnt;
                             p4:=0;
                             repeat
                               if p1>0 then begin
                                 get2(p1,rot_rec);
                                 curve_arr[p3,1]:=(rot_rec.rx-e_low2)/scale;
                                 curve_arr[p3,2]:=(rot_rec.ry-n_low2)/scale;
                                 p3:=p3+1;
                                 p4:=p4+1;
                                 case p4 of
                                   1 :  p1:=p2;
                                   2 :  p1:=cen_pt;
                                   3 :  p1:=ln_type;
                                   4 :  p1:=pen;
                                 end{case};
                               end;
                             until (p4=5) or (p1<=0);
                             if p1<0 then { trigger to draw line }
                               begin
                                 curve_arr[p3,1]:=curve_arr[p3-1,1];
                                 curve_arr[p3,2]:=curve_arr[p3-1,2];
                                 curve_arr[1,1]:=curve_arr[2,1];
                                 curve_arr[1,2]:=curve_arr[2,2];
                                 poly_curve(p3);
                                 polly_cnt:=2;
                               end
                             else polly_cnt:=p3;
                           end{case#20};
                      end{case code};
                    end{if ln_flag}
                  end{while not eof(sf[0])};
              if grid_flag>0 then draw_grid;
              draw_window;
            end{if page flag};
{ this is what to do after all pages } { plot(-0.1,-0.1,pu); }
          end{For j};
      end{For i};
    put_legent;
    plt_reset;
    close(sf[0]);
    close(led_file);
    close(rot_file);
  end{if ln_file_flag};
end;
