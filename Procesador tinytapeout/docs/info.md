## How it works

Este proyecto implementa un sistema RISC-V completo basado en el procesador FemtoRV32 "Quark". El sistema incluye:

- **Procesador FemtoRV32**: Implementación mínima del set de instrucciones RV32I
- **Memoria SPI Flash**: Para almacenamiento de programa
- **Memoria SPI RAM**: Para memoria de datos
- **Periférico UART**: Para comunicación serie
- **Sistema de memoria mapeada**: Con direccionamiento para diferentes periféricos

## How to test

1. **Programación**: El código se carga en la memoria SPI Flash
2. **Comunicación**: Usa UART a 115200 baudios para comunicación
3. **Operación**: El sistema ejecuta programas RISC-V desde la flash

## External hardware

- Memoria SPI Flash externa
- Memoria SPI RAM externa  
- Interface UART para comunicación