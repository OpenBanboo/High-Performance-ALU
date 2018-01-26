// Radix-4 divider
// 5 pinelines
module Divider

# (parameter WF = 9)

(input [WF+4:0] x, d, 
 input Clk, input Enable, input Reset_n,
 output reg [WF-1:0] Q, output reg EnqOut);
 
 reg EnableDey1, EnableDey2, EnableDey3, EnableDey4;
 
 always @ (posedge Clk or negedge Reset_n)
  if (Reset_n == 0)
    begin
    	EnableDey1 <= 0;    EnableDey2 <= 0;
    	EnableDey3 <= 0;    EnqOut <= 0;
    end
  else
    begin
    	EnableDey1 <= Enable;       EnableDey2 <= EnableDey1;
    	EnableDey3 <= EnableDey2;   EnqOut <= EnableDey3;
    end
 
 
 // q = x/d + rem, x <= d
 
// Normalize d to [0.5, 1)

reg [WF+4:0] Nrm_d, Nrm_x;
reg [3:0] NumShiftBits;

integer Index;
integer found;

always @ *
  begin
  	found = 0;
    if (Enable) 
      begin     
        for (Index = WF+4; Index >= 0; Index = Index -1)
          if (d[Index] && (!found))
            begin
            	found = 1;
            	NumShiftBits = WF+4-Index;
            end
      end 	  
    else 
      begin
      	 NumShiftBits = 0;
      end
  end
    

always @ (posedge Clk or negedge Reset_n)
  if (Reset_n == 0)
    begin
    	Nrm_d <= 0;    Nrm_x <= 0;
    end
  else
    if (Enable)
      begin
      	Nrm_d <= d << NumShiftBits;
      	Nrm_x <= x << NumShiftBits;
      end
     
//*********************** 1st stage ***********************//

reg signed [6:0] m2, m1, m0, mm1;

always @ *
  if (EnableDey1)
    case (Nrm_d[WF+3:WF+1])
    	3'b000: begin
    		        m2 = 12;   m1 = 4;   m0 = -4;   mm1 = -13;    		        
    		      end
    	3'b001: begin                                         
    		        m2 = 14;   m1 = 4;   m0 = -6;   mm1 = -15;  
    		      end                                           
    	3'b010: begin                                         
    		        m2 = 15;   m1 = 4;   m0 = -6;   mm1 = -16;  
    		      end                                           
    	3'b011: begin                                         
    		        m2 = 16;   m1 = 4;   m0 = -6;   mm1 = -18;  
    		      end                                           
    	3'b100: begin                                         
    		        m2 = 18;   m1 = 6;   m0 = -8;   mm1 = -20;  
    		      end                                           
    	3'b101: begin                                         
    		        m2 = 20;   m1 = 6;   m0 = -8;   mm1 = -20;  
    		      end 
    	3'b110: begin                                         	      
    		        m2 = 20;   m1 = 8;   m0 = -8;   mm1 = -22;  	      
    		      end                                           	      
    	3'b111: begin                                         	      
    		        m2 = 24;   m1 = 8;   m0 = -8;   mm1 = -24;  	      
    		      end                                           	                                                
    endcase
  else
    begin
    	m2 = 0;   m1 = 0;   m0 = 0;   mm1 = 0;
    end
    
wire signed [WF+7:0] w0Times4, w1Times4;   // w0 = x/4;
reg signed [WF+7:0] w1Ext, w2Ext;  
wire [WF+5:0] w1, w2;  
         
wire signed [6:0] yHat0, yHat1; 
wire signed [2:0] q1, q2;
wire signed [WF+6:0] mq1d, mq2d;

assign w0Times4 = Nrm_x;
assign yHat0 = w0Times4[WF+7:WF+1];

DivLUT DivLUT1 (.m2(m2), .m1(m1), .m0(m0), .mm1(mm1), .yHat(yHat0), 
                .d(Nrm_d), .Enable(EnableDey1), .q(q1), .mqd(mq1d));

always @ *
  if (EnableDey1)
    w1Ext = w0Times4 + mq1d;
  else
    w1Ext = 0;

assign w1 =  w1Ext[WF+5:0]; 
assign w1Times4 = w1 << 2;
assign yHat1 = w1Times4[WF+7:WF+1];

DivLUT DivLUT2 (.m2(m2), .m1(m1), .m0(m0), .mm1(mm1), .yHat(yHat1), 
                .d(Nrm_d), .Enable(EnableDey1), .q(q2), .mqd(mq2d));

always @ *
  if (EnableDey1)
    w2Ext = w1Times4 + mq2d;
  else
    w2Ext = 0;

assign w2 =  w2Ext[WF+5:0]; 

reg signed [6:0] m2Dey1, m1Dey1, m0Dey1, mm1Dey1;
reg signed [2:0] q1Dey1, q2Dey1;
reg [WF+4:0] dDey1;
reg [WF+5:0] w2Dey1;

always @ (posedge Clk or negedge Reset_n)
  if (Reset_n == 0)
    begin
    	m2Dey1 <= 0;   m1Dey1 <= 0;   m0Dey1 <= 0;   mm1Dey1 <= 0;
    	q1Dey1 <= 0;   q2Dey1 <= 0;
    	dDey1 <= 0;    w2Dey1 <= 0;
    end
  else
    if (EnableDey1)
      begin
      	m2Dey1 <= m2;   m1Dey1 <= m1;   m0Dey1 <= m0;   mm1Dey1 <= mm1;   
      	q1Dey1 <= q1;   q2Dey1 <= q2;                                  
      	dDey1 <= Nrm_d;     w2Dey1 <= w2;                                  
      end

//*********************** 2nd stage ***********************//     

wire signed [WF+7:0] w2Times4, w3Times4;                            
reg signed [WF+7:0] w3Ext, w4Ext;                                               
wire [WF+5:0] w3, w4;                                                           
                                                                                
wire signed [6:0] yHat2, yHat3;                                                 
wire signed [2:0] q3, q4;                                                        
wire signed [WF+6:0] mq3d, mq4d;                                                 
                                                                                
assign w2Times4 = w2Dey1 << 2;                                                        
assign yHat2 = w2Times4[WF+7:WF+1];                                             
                                                                                
DivLUT DivLUT3 (.m2(m2Dey1), .m1(m1Dey1), .m0(m0Dey1), .mm1(mm1Dey1), .yHat(yHat2),             
                .d(dDey1), .Enable(EnableDey2), .q(q3), .mqd(mq3d));                
                                                                                
always @ *                                                                      
  if (EnableDey2)                                                                
    w3Ext = w2Times4 + mq3d;                                                    
  else                                                                          
    w3Ext = 0;                                                                  
                                                                                
assign w3 =  w3Ext[WF+5:0];                                                     
assign w3Times4 = w3 << 2;                                                      
assign yHat3 = w3Times4[WF+7:WF+1];                                             
                                                                                
DivLUT DivLUT4 (.m2(m2Dey1), .m1(m1Dey1), .m0(m0Dey1), .mm1(mm1Dey1), .yHat(yHat3),              
                .d(dDey1), .Enable(EnableDey2), .q(q4), .mqd(mq4d));                
                                                                                
always @ *                                                                      
  if (EnableDey2)                                                                
    w4Ext = w3Times4 + mq4d;                                                    
  else                                                                          
    w4Ext = 0;                                                                  
                                                                                
assign w4 =  w4Ext[WF+5:0];                                                     
                                                                                
reg signed [6:0] m2Dey2, m1Dey2, m0Dey2, mm1Dey2;                               
reg signed [2:0] q1Dey2, q2Dey2, q3Dey1, q4Dey1;                                                
reg [WF+4:0] dDey2;                                                             
reg [WF+5:0] w4Dey1;                                                            
                                                                                
always @ (posedge Clk or negedge Reset_n)                                       
  if (Reset_n == 0)                                                             
    begin                                                                       
    	m2Dey2 <= 0;   m1Dey2 <= 0;   m0Dey2 <= 0;   mm1Dey2 <= 0;                
    	q1Dey2 <= 0;   q2Dey2 <= 0;   q3Dey1 <= 0;   q4Dey1 <= 0;                                            
    	dDey2 <= 0;    w4Dey1 <= 0;                                               
    end                                                                         
  else                                                                          
    if (EnableDey2)                                                             
      begin                                                                     
      	m2Dey2 <= m2Dey1;   m1Dey2 <= m1Dey1;   m0Dey2 <= m0Dey1;   mm1Dey2 <= mm1Dey1;         
      	q1Dey2 <= q1Dey1;   q2Dey2 <= q2Dey1;   q3Dey1 <= q3;       q4Dey1 <= q4;                                         
      	dDey2 <= dDey1;     w4Dey1 <= w4;                                           
      end                                                                       

//*********************** 3rd stage ***********************// 

wire signed [WF+7:0] w4Times4, w5Times4;                            
reg signed [WF+7:0] w5Ext;                                               
wire [WF+5:0] w5;                                                           
                                                                                
wire signed [6:0] yHat4, yHat5;                                                 
wire signed [2:0] q5, q6;                                                        
wire signed [WF+6:0] mq5d, mq6d;                                                 
                                                                                
assign w4Times4 = w4Dey1 << 2;                                                        
assign yHat4 = w4Times4[WF+7:WF+1];                                             
                                                                                
DivLUT DivLUT5 (.m2(m2Dey2), .m1(m1Dey2), .m0(m0Dey2), .mm1(mm1Dey2), .yHat(yHat4),             
                .d(dDey2), .Enable(EnableDey3), .q(q5), .mqd(mq5d));                
                                                                                
always @ *                                                                      
  if (EnableDey3)                                                                
    w5Ext = w4Times4 + mq5d;                                                    
  else                                                                          
    w5Ext = 0;                                                                  
                                                                                
assign w5 =  w5Ext[WF+5:0];                                                     
assign w5Times4 = w5 << 2;                                                      
assign yHat5 = w5Times4[WF+7:WF+1];                                             
                                                                                
DivLUT DivLUT6 (.m2(m2Dey2), .m1(m1Dey2), .m0(m0Dey2), .mm1(mm1Dey2), .yHat(yHat5),              
                .d(dDey2), .Enable(EnableDey3), .q(q6), .mqd(mq6d));                
                                                                                                                                 
                                                                                                             
reg signed [2:0] q1Dey3, q2Dey3, q3Dey2, q4Dey2, q5Dey1, q6Dey1;                                                                                                           
                                                                                
always @ (posedge Clk or negedge Reset_n)                                       
  if (Reset_n == 0)                                                             
    begin                                                                                     
    	q1Dey3 <= 0;   q2Dey3 <= 0;   q3Dey2 <= 0;   q4Dey2 <= 0;   q5Dey1 <= 0;   q6Dey1 <= 0;                                                                                       
    end                                                                         
  else                                                                          
    if (EnableDey3)                                                             
      begin                                                                            
      	q1Dey3 <= q1Dey2;   q2Dey3 <= q2Dey2;   q3Dey2 <= q3Dey1;   q4Dey2 <= q4Dey1; 
      	q5Dey1 <= q5;       q6Dey1 <= q6;                                                                                 
      end 
      
//*********************** 4th stage ***********************//                  

// On the fly conversion
                                                                                
reg [1:0] QN1, QM1, q2t, q3t, q4t, q5t, q6t, q7t; 
reg [3:0] QN2, QM2;
reg [5:0] QN3, QM3;
reg [7:0] QN4, QM4;
reg [9:0] QN5, QM5;
reg [11:0] QN6, QM6;

always @ *
  if (EnqOut)
    begin 
    	// initial
    	QN1 = q1Dey3[1:0];   QM1 = QN1-1;
    	
    	// 4 bits quotient
    	if (q2Dey3[2] == 0)
    	  QN2 = {QN1, q2Dey3[1:0]};   
    	else
        QN2 = {QM1, q2Dey3[1:0]};   
      
      q2t = q2Dey3[1:0] - 1;
        
      if (q2Dey3 > 0)
        QM2 = {QN1, q2t};
      else
        QM2 = {QM1, q2t};                       	
    end
  else
    begin 
    	QN1 = 0;   QM1 = 0;      
    	QN2 = 0;   QM2 = 0;   q2t = 0;         	                    	
    end
        
always @ *              
  if (EnqOut)       
    begin
    	// 6 bits quotient 
    	if (q3Dey2[2] == 0)              
    	  QN3 = {QN2, q3Dey2[1:0]};      
    	else                             
    	  QN3 = {QM2, q3Dey2[1:0]};      
    	                                 
    	q3t = q3Dey2[1:0] - 1;           
    	                                 
    	if (q3Dey2 > 0)                  
    	  QM3 = {QN2, q3t};              
    	else                             
    	  QM3 = {QM2, q3t};  
    	  
    	// 8 bits quotient                
    	if (q4Dey2[2] == 0)               
    	  QN4 = {QN3, q4Dey2[1:0]};       
    	else                              
    	  QN4 = {QM3, q4Dey2[1:0]};       
    	                                  
    	q4t = q4Dey2[1:0] - 1;            
    	                                  
    	if (q4Dey2 > 0)                   
    	  QM4 = {QN3, q4t};                           
    	else                              
    	  QM4 = {QM3, q4t};                 
    end 
  else
    begin
    	QN3 = 0;    QM3 = 0;    q3t = 0;  
    	QN4 = 0;    QM4 = 0;    q4t = 0;     	      	
    end            

always @ *             
  if (EnqOut)                                                                    
    begin
    	// 10 bits quotient                  
    	if (q5Dey1[2] == 0)                 
    	  QN5 = {QN4, q5Dey1[1:0]};         
    	else                                
    	  QN5 = {QM4, q5Dey1[1:0]};         
    	                                    
    	q5t = q5Dey1[1:0] - 1;              
    	                                    
    	if (q5Dey1 > 0)                     
    	  QM5 = {QN4, q5t};                 
    	else                                
    	  QM5 = {QM4, q5t};                 
    	                                    
    	// 12 bits quotient                  
    	if (q6Dey1[2] == 0)                 
    	  QN6 = {QN5, q6Dey1[1:0]};         
    	else                                
    	  QN6 = {QM5, q6Dey1[1:0]};         
    	                                    
    	q6t = q6Dey1[1:0] - 1;              
    	                                    
    	if (q6Dey1 > 0)                     
    	  QM6 = {QN5, q6t};                 
    	else                                
    	  QM6 = {QM5, q6t};                     	    	    	    	    		
    end
  else
    begin 
    	QN5 = 0;   QM5 = 0;   q5t = 0; 
    	QN6 = 0;   QM6 = 0;   q6t = 0;      	       	 
    end

    	  
always @ *        	    
    if (EnqOut) 
      begin
      	Q = QN6[9:1];     // Equal to shift left 2 bits
      end                                      	  
    	                      
endmodule                                               