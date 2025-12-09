`default_nettype none

module tt_um_mult4_complete (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Sincronizar reset
  reg resetn;
  always @(negedge clk) resetn <= rst_n;

  // Instancia del multiplicador de 4 bits
  mult_4 mult_4_inst (
    .clk(clk),
    .rst(!resetn),           // reset activo en alto
    .init(uio_in[0]),        // señal de inicio
    .A(ui_in[3:0]),          // operando A (4 bits)
    .B(ui_in[7:4]),          // operando B (4 bits)
    .result(uo_out[7:0]),    // resultado (8 bits) - çç
    .done(uio_out[1])        // señal de terminación
  );
  
  // Asignaciones de salida
  assign uio_out[7:2] = 6'b0;
  assign uio_out[0] = 1'b0;
  
  // Todos los pines bidireccionales como entradas (0=entrada)
  assign uio_oe = 8'b00000000;

  // Prevenir warnings por señales no usadas
  wire _unused_ena = ena;
  wire [7:0] _unused_uio_in = uio_in;
  wire [7:0] _unused_uio_oe = uio_oe;

endmodule

module mult_4 (
  input  wire       clk,
  input  wire       rst,
  input  wire       init,
  input  wire [3:0] A,
  input  wire [3:0] B,
  output wire [7:0] result,  // ç
  output wire       done
);

  // Señales internas
  wire w_sh;
  wire w_reset;
  wire w_add;
  wire w_z;
  
  wire [7:0] w_A;
  wire [3:0] w_B;
  
  // Instancias de los módulos
  rsr_4 rsr0 (
    .clk(clk),
    .in_B(B),
    .shift(w_sh),
    .load(w_reset),
    .s_B(w_B)
  );
  
  lsr_4 lsr0 (
    .clk(clk),
    .in_A(A),
    .shift(w_sh),
    .load(w_reset),
    .s_A(w_A)
  );
  
  comp_4 comp0 (
    .B(w_B),
    .z(w_z)
  );
  
  acc_4 acc0 (
    .clk(clk),
    .A(w_A),
    .add(w_add),
    .rst(w_reset),
    .result(result)  // ç
  );
  
  control_mult_4 control0 (
    .clk(clk),
    .rst(rst),
    .lsb_B(w_B[0]),
    .init(init),
    .z(w_z),
    .done(done),
    .sh(w_sh),
    .reset(w_reset),
    .add(w_add)
  );

endmodule

// Módulo LSR (Left Shift Register) adaptado para 4 bits
module lsr_4 (
  input  wire       clk,
  input  wire [3:0] in_A,
  input  wire       shift,
  input  wire       load,
  output reg  [7:0] s_A
);

  always @(negedge clk) begin
    if (load) begin
      // Cargar y extender a 8 bits
      s_A <= {4'b0, in_A};
    end else if (shift) begin
      // Desplazar a la izquierda
      s_A <= s_A << 1;
    end
    // else mantener valor actual
  end

endmodule

// Módulo RSR (Right Shift Register) adaptado para 4 bits
module rsr_4 (
  input  wire       clk,
  input  wire [3:0] in_B,
  input  wire       shift,
  input  wire       load,
  output reg  [3:0] s_B
);

  always @(negedge clk) begin
    if (load) begin
      s_B <= in_B;
    end else if (shift) begin
      s_B <= s_B >> 1;
    end
    // else mantener valor actual
  end

endmodule

// Módulo comparador adaptado para 4 bits
module comp_4 (
  input  wire [3:0] B,
  output reg        z
);

  always @(*) begin
    // z = 1 cuando B == 0
    z = (B == 4'b0) ? 1'b1 : 1'b0;
  end

endmodule

// Módulo acumulador adaptado para 8 bits
module acc_4 (
  input  wire       clk,
  input  wire [7:0] A,
  input  wire       add,
  input  wire       rst,
  output reg  [7:0] result  //ç
);

  always @(negedge clk) begin
    if (rst) begin
      result <= 8'b0;
    end else if (add) begin
      result <= result + A;
    end
    // else mantener valor actual
  end

endmodule

// Módulo controlador adaptado para 4 bits
module control_mult_4 (
  input  wire clk,
  input  wire rst,
  input  wire lsb_B,
  input  wire init,
  input  wire z,
  output reg  done,
  output reg  sh,
  output reg  reset,
  output reg  add
);

  // Estados de la máquina de control
  parameter START  = 3'b000;
  parameter CHECK  = 3'b001;
  parameter SHIFT  = 3'b010;
  parameter ADD    = 3'b011;
  parameter END    = 3'b100;
  
  reg [2:0] state;
  reg [2:0] count;  // Contador para 4 bits (0-3)
  
  // Inicialización
  initial begin
    done  = 1'b0;
    sh    = 1'b0;
    reset = 1'b0;
    add   = 1'b0;
    state = START;
    count = 3'b0;
  end
  
  always @(posedge clk) begin
    if (rst) begin
      // Reset asíncrono
      state <= START;
      done  <= 1'b0;
      sh    <= 1'b0;
      reset <= 1'b0;
      add   <= 1'b0;
      count <= 3'b0;
    end else begin
      case (state)
        START: begin
          done  <= 1'b0;
          sh    <= 1'b0;
          reset <= 1'b1;  // Activar reset de los registros
          add   <= 1'b0;
          count <= 3'b0;
          
          if (init) begin
            state <= CHECK;
            reset <= 1'b0;  // Desactivar reset después de 1 ciclo
          end else begin
            state <= START;
          end
        end
        
        CHECK: begin
          done  <= 1'b0;
          sh    <= 1'b0;
          reset <= 1'b0;
          add   <= 1'b0;
          
          if (lsb_B) begin
            state <= ADD;
          end else begin
            state <= SHIFT;
          end
        end
        
        SHIFT: begin
          done  <= 1'b0;
          sh    <= 1'b1;    // Activar desplazamiento
          reset <= 1'b0;
          add   <= 1'b0;
          
          if (z) begin
            // Si B == 0, terminar
            state <= END;
          end else if (count == 3'b011) begin
            // Ya procesamos 4 bits
            state <= END;
          end else begin
            state <= CHECK;
            count <= count + 1;
          end
        end
        
        ADD: begin
          done  <= 1'b0;
          sh    <= 1'b0;
          reset <= 1'b0;
          add   <= 1'b1;    // Activar suma
          state <= SHIFT;
        end
        
        END: begin
          done  <= 1'b1;    // Señal de terminación
          sh    <= 1'b0;
          reset <= 1'b0;
          add   <= 1'b0;
          
          // Esperar a que init sea bajo para volver a START
          if (!init) begin
            state <= START;
          end
        end
        
        default: state <= START;
      endcase
    end
  end

endmodule