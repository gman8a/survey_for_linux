uses crt,
     basics4,
     filestuf,
     plot1,
     plot51;

procedure survey_plot;

{$I plot2}

procedure start_plot;
  begin
    writeln;
    active_shp:=0;
    shp_pt_off[0]:=0;
    shp_c_scale[0]:=1;
    shp_m_scale[0]:=1;
    shp_page_rot[0]:=0;
    shp_size_stk[0]:=1;
    arrow_ends:=1;
    polly_cnt:=2;
    do_it:=true;

    quest2(0,0,'[L]arge or [S]mall Plotter Sheet ? ',['L','S'],false);
    large:=(response='L');
    if large then
         begin plt_x:=34.00;
               plt_y:=21.50;
         end
    else begin plt_x:=plt_x_mf;
               plt_x_mf:=plt_y_mf;
               plt_y_mf:=plt_x;
               plt_x:=21.50;
               plt_y:=16.00;
         end;

    led_pos[1,1]:=0.80;         led_pos[1,2]:=plt_y;
    led_pos[2,1]:=plt_x/2-4.00; led_pos[2,2]:=plt_y;
    led_pos[3,1]:=plt_x-8.00;   led_pos[3,2]:=plt_y;
    led_pos[4,1]:=0.80;         led_pos[4,2]:=plt_y/2+2;
    led_pos[5,1]:=plt_x-8.00;   led_pos[5,2]:=plt_y/2+2;
    led_pos[6,1]:=0.80;         led_pos[6,2]:=4.90;
    led_pos[7,1]:=plt_x/2-4.00; led_pos[7,2]:=4.90;
    led_pos[8,1]:=plt_x-8.00;   led_pos[8,2]:=4.90;

    writeln;
    write(get_dir(fn3+'?',false));
    write('Last character of Plot Line File: ',fn3);
    quest2(0,0,' ? ',[' ','0'..'9','A'..'Z','a'..'z'],false);
    lc:=response;
    assign(sf[0],fn3+lc);
    {$I-} reset(sf[0]); {$I+}
    if IOresult=0 then
      begin
        ln_file_flag:=true;
        readln(sf[0],code,scale,rot_ang,xt,yt,grid_flag,pt_Xhair,pt_lab,led,low_pt,n_low,e_low,n_up,e_up);
        at_scale:=scale; { in_case not set, he should set in ln_file }
        m_sf:=shp_c_scale[active_shp]*at_scale/scale;
        up_pt:=no_pts;    { last point number in plot file }
        border:=(code>0);
      end
    else begin
           ln_file_flag:=false;
           writeln;
           writeln(^G,'Can not find file:',fn3,response);
           delay(2500);
         end;
    end;

procedure pt_pt_line(p1,p2:integer);
 procedure line_lab;
   var
     vert_off :real;
     distance2:real;
  begin
    t_code:=t_code2;
    pt_to_pt(p1,p2,r,asz1);
    if (t_code in ['A','B','L','P','D','V','Z','S','T']) and (r>0) then
      begin
        caps(lab);

        if cur_ln>9 then vert_off:=maxr(0.050*40/scale,0.030)
        else vert_off:=0.030;
        if t_code='T' then vert_off:=vert_off+0.105;
        if (pos('R',lab) in [2,3,4]) then pt_to_pt(p2,p1,r,asz1)
        else pt_to_pt(p1,p2,r,asz1);
        if t_code='A' then asz3:=asz1
        else begin
               asz3:=rad_bear(asz_rad(asz1));
               delete(asz3,2,1);
             end;
        delete(asz3,12,1);
        pt_to_pt(p1,p2,r,asz1);
        if not (t_code in ['V','Z']) then
          case t_code of
            'L': if r/scale<0.55 then t_code:='P';
        'T','S': if r/scale<1.80 then t_code:='P';
            else if r/scale<1.00 then t_code:='P';
          end{case};
        get(p1,pt_rec);
        with pt_rec do
          begin
            case t_code of
              'P':begin
                    if r/2>0.13*scale then
                      distance:=r/2-0.105*scale { 1 char len. inches }
                    else
                      begin
                        (* distance:=r/2+0.05*scale; t_code:='V'; perp_ang:=0; *)
                        distance:=r/2;
                      end;
                  end;
              'L':distance:=r/2-0.25*scale;
              'D','B','A':distance:=r/2-0.46*scale;
              'V':distance:=r/2+0.052*scale;
              'Z':distance:=r/2-0.052*scale;
          'T','S':distance:=r/2-0.850*scale;
            end{case};
            distance2:=distance;
            distance:=sqrt(sqr(distance2)+sqr(vert_off*scale));
            case t_code of
               'V':aszmith:=asz_rad(asz1)-arctan(0.11/(distance2/scale));
               'Z':aszmith:=asz_rad(asz1)+arctan(0.11/(distance2/scale));
               'T':aszmith:=asz_rad(asz1)+arctan(vert_off/(distance2/scale));
              else begin
                     if pos('T',lab)=2 then (** Changed **)
                       aszmith:=asz_rad(asz1)+arctan(vert_off/(distance2/scale))
                     else
                       aszmith:=asz_rad(asz1)-arctan(vert_off/(distance2/scale));
                   end;
            end{case};
            from_pt:=p1;
            code:=0;
          end;
        calculate(pt_rec); with pt_rec do rotate(east,north,0,0,rot_ang);
        a1:=(pi/2-asz_rad(asz1))*180/pi;
        case t_code of
          'V':a1:=a1+90;
          'Z':a1:=a1+270;
        end{case};
        adj_ang(a1);
        with pt_rec do
          case t_code of
            'P': { print legend draw led. marker }
               begin
                 lab_cnt_l:=lab_cnt_l+1;
                 str(lab_cnt_l,any_str); any_str:='L'+any_str;
                 symbol((east-e_low2)/scale,(north-n_low2)/scale,7,a1+rot_ang,any_str,cur_pen);
                 writeln(led_file,any_str:3,r:9:3,'  ',asz3);
               end;
'V','Z','S','T':begin
                  str(r:9:3,any_str); any_str:=asz3+any_str+'''';
                  if (perp_ang<>0) and not (t_code in ['S','T']) then (** Change **)
                    a1:=perp_ang; { off due east }
                  symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str,cur_pen);
                end;
            else  { draw or plot label or led. marker }
              begin
                if t_code='L' then str(r:6:2,any_str) else str(r:9:3,any_str);
                any_str:=any_str+'''';
                symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,any_str+'  ',cur_pen);
                if t_code<>'L' then
                  begin
                    aszmith:=asz_rad(asz1)+arctan((0.105+vert_off)/(distance2/scale));
                    distance:=sqrt(sqr(distance2)+sqr((0.105+vert_off)*scale));
                    calculate(pt_rec); with pt_rec do rotate(east,north,0,0,rot_ang);
                    symbol((east-e_low2)/scale,(north-n_low2)/scale,6,a1+rot_ang,asz3,cur_pen);
                  end;
              end;
          end{case};
    end{if t_code=};
  end;

  procedure box_label1;   { center box label on line }
    var v_os      : real; { vertical offset }
        distance2 : real;
    begin
      with box_label_rec0 do
        if do_it_flag then
          begin
            pt_to_pt(p1,p2,r,asz1);
            with pt_rec do
              begin
                v_os      := letter_height/2;
                distance  := (r -(box_length-6/7*letter_height)*scale)/2;
                distance2 := distance;
                distance  := sqrt(sqr(distance2) + sqr(v_os));
                aszmith   := asz_rad(asz1) + arctan(v_os/distance2*scale);
                from_pt   := p1;
                code      := 0;

                calculate(pt_rec);
                with pt_rec do rotate(east,north,0,0,rot_ang);
                a1:=(pi/2-asz_rad(asz1))*180/pi;

                setchr(letter_height,0,0,0);
                symbol((east -e_low2)/scale,
                       (north-n_low2)/scale,
                       0,                         { use pre setchr type }
                       a1+rot_ang,box_label,cur_pen);
              end;
          end;
    end;

 begin  {*** main proc. pt_pt_line ****};
    fillchar(box_label_rec0,sizeof(box_label_rec0),^@);

    chk_pt_in_window(p1);
    if not ln_flag then chk_pt_in_window(p2);
    if ln_flag then begin
      get2(p1,rot_rec);
      get2(p2,rot_rec2);
      if odd(code) then
        begin
          plot_pt_no(p2);
          plot_pt_no(p1);
        end;
      if (pt_xhair>0) and not (rot_rec.plotted) then { figure which end get x-hairs }
        begin
          pt_end:=1;
          rot_rec.plotted:=true;
          put2(p1,rot_rec);
        end
      else pt_end:=0;
      if (pt_xhair>0) and not (rot_rec2.plotted) then
        begin
          if pt_end=1 then pt_end:=3 else pt_end:=2;
          rot_rec2.plotted:=true;
          put2(p2,rot_rec2)
        end;
{==========================================================================}
      line(( rot_rec.rx-e_low2)/scale,( rot_rec.ry-n_low2)/scale,
            (rot_rec2.rx-e_low2)/scale,(rot_rec2.ry-n_low2)/scale,pt_end);
      line_lab;
      box_label1;


      if draw_marker then {Line markers}
        begin
          if cen_pt=3 then
            begin
              get2(p1,rot_rec);
              with rot_rec do
                marker((rx-e_low2)/scale,(ry-n_low2)/scale,cur_size,cur_marker);
             end;
          case cen_pt of
            2..9999:get2(p2,rot_rec);
            else get2(p1,rot_rec);
          end{case};
          with rot_rec do
            marker((rx-e_low2)/scale,(ry-n_low2)/scale,cur_size,cur_marker);
        end{draw_marker};
    end;
  end{pt_pt_line};

{$I plot3}

begin { ***** M a i n   L i n e ***** }
  file_flag:=false;
  tag_flag:=true;
  dbl_ln_len:=0.05;
{   last_drv:=lastdisk; }
  dbl_ln_len:=0.05;
  writeln('PC-Turbo Survey Plotting System.  Ver 3.00 - 8808.04');
  writeln('Copyright 1987 by: Gary Argraves  All Rights Reserved');
  writeln('=====================================================');
  open_pt_file;
  demo:=false;
  mult_pen_flag:=false;
  if file_flag then
    begin
      dig_des:=fn7+'DR';
      if exist('plot.cfg') then
        begin
          assign(led_file,'plot.cfg'); reset(led_file);
          readln(led_file,dig_des);
          readln(led_file,plt_x_mf,plt_y_mf); { get units/inch }
          readln(led_file,i); if i>1 then mult_pen_flag:=true;
          while copy(dig_des,1,1)=' ' do delete(dig_des,1,1);
          i:=1; repeat dig_des[i]:=upcase(dig_des[i]);
                       i:=i+1;
                until copy(dig_des,i,1)=' ';
          dig_des:=copy(dig_des,1,i-1);
          if dig_des='DR' then dig_des:=fn7+'DR';
          close(led_file);
        end
      else begin plt_x_mf:=1000.00; plt_y_mf:=1000.00; end;
      assign(out_file,dig_des);
      rewrite(out_file);
      survey_plot;
      if alt_flag then close(alt_pt_file) else close(pt_file);
      close(out_file);
    end;
end.
