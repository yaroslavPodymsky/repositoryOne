program todo;
uses crt;
label m;


type
task = record
data:string;
m:boolean;
end;  


var
a:array[1..250] of task;
c,g,x,z,v,i:integer;
t:string;

begin
clrscr;
m:

    writeln;
    TextBackGround(black);
    textcolor(yellow); 
    writeln('Нажмите "1" чтобы записать задачу ');
    writeln('Нажмите "2" чтобы посмотреть список задач ');
    writeln('Нажмите "3" чтобы завершить задачу ');         
    writeln('Нажмите "4" чтобы посмотреть завершенные задачи ');
    readln(c);
    if (c >= 5) or (c < 1)then
	    begin
    writeln('Такой команды не существует! ');
    delay(2000);
    clrscr;
    end;
{условие 1}   if (c=1)then
              begin
		      clrscr;
	      writeln('Напишите задачу : ');
              readln(t);
              for i:=1 to 250 do
                     	 begin
                         if (a[i].data <> '')then continue;
                         if (a[i].data = '')then
                                                 begin
                           			 a[i].data:=t;
			   			 a[i].m:=true;
                           		 	 break;
                          			 end;
                         end;
			 clrscr;
       			 goto m;
              end
{условие 2}   else if (c=2)then
	      begin 
	      clrscr;
	      x:=0;
	      for i:=1 to 250 do
		      begin
			      if (a[i].data = '')then continue;
			      if (a[i].data <> '') and (a[i].m = true)then
				      						begin
										x:=x+1;
										end;
	              end;
	      if (x = 0)then
 	      writeln('Список задач пуст')
	      else
	      writeln('Вот список ваших задач :');
	      writeln();
	      z:=1;
              for i:=1 to 250 do
              			begin
          		        if (a[i].data = '' )then continue;
                          	if (a[i].data <> '') and (a[i].m = true)then
                         						 begin
                              						 writeln(z,': ',a[i].data);
									 z:=z+1;
                               						 end;
                      		end;
                                goto m;
              end
{условие 3}   else if (c=3)then
              begin
	      clrscr;
	      x:=0;
              for i:=1 to 250 do
                      begin
                              if (a[i].data = '')then continue;
                              if (a[i].data <> '') and (a[i].m = true)then
                                                                                begin
                                                                                x:=x+1;
                                                                                end;
                      end;
              if (x = 0)then
		 		     begin
             			     writeln('Список задач пуст');
				     writeln();
	    			     goto m;
	     			     end
              else
	      writeln('Вот список ваших задач :');
              writeln();
	      x:=1;
              for i:=1 to 250 do
                                 begin
                                 if (a[i].m = false)then continue;
                                 if (a[i].data <> '') and (a[i].m = true)then
                                                 			begin
                                                 			writeln(x,': ',a[i].data);
						 			x:=x+1;
									end;
				 end;
										begin
										writeln();
                                 						writeln('Введите № задачи которую вы хотите удалить ');
                               	 						readln(v);
										clrscr;
										g:=1;
										for i:=1 to 250 do 
													begin
									                 			if (a[i].m = false)then continue;
						                                		        	if (a[i].data <> '') and (a[i].m = true)then
                                                     					                       					begin
																			if (g=v)then
														              					begin
																			        a[i].m:=false;
																				writeln('Задача ',a[i].data,' удалена');
															   					g:=g+1;
																				end
													        					else
																			g:=g+1;			
																		end;
																		
													end;
													if (v > x-1)then
														begin
														writeln('Задачи с таким № не найдено');	
														end;
													goto m;
	     			 						end;
	      end
{условие 4}   else if (c=4)then
	      begin
 	      clrscr;
	      x:=0;
              for i:=1 to 250 do
                      begin
                              if (a[i].data = '')then continue;
                              if (a[i].data <> '') and (a[i].m = false)then
                                                                                begin
                                                                                x:=x+1;
                                                                                end;
                      end;
              if (x = 0)then
              writeln('Список завершеных задач пуст')
              else
	      writeln('Завершенные задачи : ');
	      writeln();
	      x:=1;
     	      for i:=1 to 250 do 
	      			begin
				if (a[i].m = true)then continue;
				if (a[i].data <> '') and  (a[i].m = false)then
				 		 begin
						 writeln(x,': ', a[i].data);
						 x:=x+1;
					         end;
				end
	      end;
	      goto m;

end.

