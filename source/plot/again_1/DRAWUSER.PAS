{ draw a user line type between two points }

  procedure draw_user_line(l_no:integer);
    var r1,ll2,
        box_length,box_height : real;
        x5,y5 : real;
    begin
      with user_line_types[l_no] do
        begin

          case line_type of
            1:begin  { regular }

              end;
            2:begin  { boxed }


              end;
            3:begin  { markered }

              end;
            4:begin
                r1:=letter_size * scale/at_scale;
                setchr(r1,r1,0,0);
                box_length := (length(box_str)+1) * cur_cs;
                box_height := 1.25 * r1;
                if box_length<ln_len then
                  begin
                    ll2:=(ln_len-box_length)/2;
                    plot(x1,y1,pu);
                    dashs(natural_line);
                    x5:=x1+sin(a1)*ll2;
                    y5:=y1+cos(a1)*ll2;                plot(x5,y5,pd);
                    dashs(0);
                    x3:=x5+sin(a1-pi/2)*box_height/2;
                    y3:=y5+cos(a1-pi/2)*box_height/2;  plot(x3,y3,pd);
                    x3:=x3+sin(a1)*box_length;
                    y3:=y3+cos(a1)*box_length;         plot(x3,y3,pd);
                    x4:=x3+sin(a1+pi/2)*box_height/2;
                    y4:=y3+cos(a1+pi/2)*box_height/2;
                    x3:=x3+sin(a1+pi/2)*box_height;
                    y3:=y3+cos(a1+pi/2)*box_height;    plot(x3,y3,pd);
                    x3:=x3+sin(a1+2*pi)*box_length;
                    y3:=y3+cos(a1+2*pi)*box_length;    plot(x3,y3,pd);
                    plot(x5,y5,pd);
                    plot(x4,y4,pu);
                    dashs(natural_line);
                    plot(x2,y2,pd);

                    {symbol((east-e_low2)/scale, (north-n_low2)/scale,0,
                           a1,box_str,cur_pen);}
                  end
                else
                  begin
                    dashs(natural_line);
                    plot(x1,y1,pu);
                    plot(x2,y2,pd);
                  end;
              end;

          end{case};

        end;

    end;
