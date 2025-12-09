## How it works

Multiplicador secuencial de 4 bits que usa algoritmo de desplazamiento y suma. Toma dos números de 4 bits y produce un resultado de 8 bits en ~15 ciclos de reloj.

## How to test

Establecer operandos: ui_in[3:0] = A, ui_in[7:4] = B

Pulsar uio_in[0] (init) en alto por 1 ciclo de reloj

Esperar que uio_out[1] (done) se ponga en alto

Leer resultado en uo_out[7:0]

Ejemplo: ui_in = 8'h35 (A=5, B=3) → resultado = 8'h0F (15)

## External hardware

Solo el chip de Tiny Tapeout. Entradas: operandos y señal init. Salidas: resultado y señal done.
