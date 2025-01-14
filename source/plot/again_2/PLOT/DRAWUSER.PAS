{ draw a user line type between two points }
  procedure draw_user_line(l_no:integer);
    var ll2,x5,y5             : real;
        chr_spacing           : real;

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
            4:with box_label_rec0 do
              begin
                letter_height := letter_size/100 * scale/at_scale;
                chr_spacing   := 6/7  * letter_height;

                box_height    := 1.33 * letter_height;
                box_length    := (length(box_str)+1) * chr_spacing;
                box_label     := box_str;
                do_it_flag    := true;

                if box_length < ln_len then
                  begin
                    ll2:=(ln_len-box_length)/2;
                    plot(x1,y1,pu);
                    dashs(natural_line);
                    x5:=x1+sin(a1)*ll2;
                    y5:=y1+cos(a1)*ll2;                  plot(x5,y5,pd);
                    dashs(0);
                    x3:=x5+sin(a1-pi/2) * box_height/2;
                    y3:=y5+cos(a1-pi/2) * box_height/2;  plot(x3,y3,pd);
                    x3:=x3+sin(a1)      * box_length;
                    y3:=y3+cos(a1)      * box_length;    plot(x3,y3,pd);
                    x4:=x3+sin(a1+pi/2) * box_height/2;
                    y4:=y3+cos(a1+pi/2) * box_height/2;
                    x3:=x3+sin(a1+pi/2) * box_height;
                    y3:=y3+cos(a1+pi/2) * box_height;    plot(x3,y3,pd);
                    x3:=x3+sin(a1+pi)   * box_length;
                    y3:=y3+cos(a1+pi)   * box_length;    plot(x3,y3,pd);
                    plot(x5,y5,pd);
                    plot(x4,y4,pu);
                    dashs(natural_line);
                    plot(x2,y2,pd);
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