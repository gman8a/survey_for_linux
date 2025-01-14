ll2:=(ln_len-box_length)/2;
                    plot(x1,y1,pu);                                 { #1 }
                    dashs(natural_line);
                    x5:=x1+sin(a1)*ll2;
                    y5:=y1+cos(a1)*ll2;             plot(x5,y5,pd); { #2 }

                    { Movement like turtle graphics would be cool }

                    dashs(0); { begin @ #3 so box height is a smooth pen line }
                    x3:=x5+sin(a1-pi/2) * box_height/2;
                    y3:=y5+cos(a1-pi/2) * box_height/2;  plot(x3,y3,pu); {#3}
                    x5:=x3; { save for return }
                    y5:=y3;

                    x3:=x3+sin(a1)      * box_length;
                    y3:=y3+cos(a1)      * box_length;    plot(x3,y3,pd); {#4}
                    x4:=x3+sin(a1+pi/2) * box_height/2;
                    y4:=y3+cos(a1+pi/2) * box_height/2;                  {#7}
                    x3:=x3+sin(a1+pi/2) * box_height;
                    y3:=y3+cos(a1+pi/2) * box_height;    plot(x3,y3,pd); {#5}
                    x3:=x3+sin(a1+pi)   * box_length;
                    y3:=y3+cos(a1+pi)   * box_length;    plot(x3,y3,pd); {#6}

                    plot(x5,y5,pd);        { return back to #3 }
                    plot(x4,y4,pu);        { #7 ; start of 2nd main line part }
                    dashs(natural_line);   { set line type }
                    plot(x2,y2,pd);        { #8 ; second main line }