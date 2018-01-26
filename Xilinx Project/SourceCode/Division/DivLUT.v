// LUT in radix-4 divider
module DivLUT

# (parameter WF = 9)

(input signed [6:0] m2, m1, m0, mm1, yHat, 
 input [WF+4:0] d, input Enable,
 output reg signed [2:0] q, output reg signed [WF+6:0] mqd);
 
always @ *
  if (Enable)
    begin
    	if (yHat >= m2)
    	  q = 2;
    	else if ((yHat >= m1) && (yHat < m2))
    	  q = 1;
    	else if ((yHat >= m0) && (yHat < m1))
    	  q = 0;
    	else if ((yHat >= mm1) && (yHat < m0))
    	  q = -1;
    	else // yHat < mm1
    	  q = -2;
    end
  else
    begin
    	q = 0;
    end
    
always @ *                       
  if (Enable)               
    begin                       
      if (q == 2)              
        mqd = -(d << 1);   // -q * d    
      else if (q == 1)         
        mqd = -d;              
      else if (q == 0)         
        mqd = 0;               
      else if (q == -1)        
        mqd = d;               
      else if (q == -2)        
        mqd = d << 1;          
      else                      
        mqd = 0;               
    end                         
  else                          
    mqd = 0;  
    
endmodule                 