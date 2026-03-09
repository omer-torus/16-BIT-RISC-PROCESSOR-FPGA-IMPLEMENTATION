@echo off
REM ================================================================================
REM   16-bit RISC Processor - Automatic Test Runner for Windows
REM ================================================================================

echo.
echo ========================================
echo    RISC Processor Test Suite
echo ========================================
echo.

REM Check if iverilog is installed
where iverilog >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Icarus Verilog not found!
    echo.
    echo Please install Icarus Verilog from:
    echo http://bleyer.org/icarus/
    echo.
    pause
    exit /b 1
)

echo Icarus Verilog found: OK
iverilog -v | findstr /C:"version"
echo.

REM ================================================================================
REM Test 1: ALU Test
REM ================================================================================

echo [1/5] Compiling ALU Test...
iverilog -g2012 -Wall -o alu_test.exe alu.v tb_alu.v
if %errorlevel% neq 0 (
    echo ERROR: ALU compilation failed!
    pause
    exit /b 1
)

echo [1/5] Running ALU Test...
vvp alu_test.exe
if %errorlevel% neq 0 (
    echo ERROR: ALU test failed!
    pause
    exit /b 1
)
echo [1/5] ALU Test: PASSED
echo.

REM ================================================================================
REM Test 2: Hazard Detection Test
REM ================================================================================

echo [2/5] Compiling Hazard Detection Test...
iverilog -g2012 -Wall -o hazard_test.exe hazard_detection_unit.v forwarding_unit.v tb_hazard_forwarding.v
if %errorlevel% neq 0 (
    echo ERROR: Hazard test compilation failed!
    pause
    exit /b 1
)

echo [2/5] Running Hazard Detection Test...
vvp hazard_test.exe
if %errorlevel% neq 0 (
    echo ERROR: Hazard test failed!
    pause
    exit /b 1
)
echo [2/5] Hazard Detection Test: PASSED
echo.

REM ================================================================================
REM Test 3: Full Processor Test
REM ================================================================================

echo [3/5] Compiling Full Processor Test...
iverilog -g2012 -Wall -o processor_test.exe register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v processor_top.v tb_processor.v
if %errorlevel% neq 0 (
    echo ERROR: Processor compilation failed!
    pause
    exit /b 1
)

echo [3/5] Running Full Processor Test...
vvp processor_test.exe
if %errorlevel% neq 0 (
    echo ERROR: Processor test failed!
    pause
    exit /b 1
)
echo [3/5] Full Processor Test: PASSED
echo.
echo Generated: processor_test.vcd (view with GTKWave)
echo.

REM ================================================================================
REM Test 4: Control Hazard Test
REM ================================================================================

echo [4/5] Compiling Control Hazard Test...
iverilog -g2012 -Wall -o control_test.exe register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v processor_top.v tb_control_hazards.v
if %errorlevel% neq 0 (
    echo ERROR: Control test compilation failed!
    pause
    exit /b 1
)

echo [4/5] Running Control Hazard Test...
vvp control_test.exe
if %errorlevel% neq 0 (
    echo ERROR: Control test failed!
    pause
    exit /b 1
)
echo [4/5] Control Hazard Test: PASSED
echo.
echo Generated: control_hazards.vcd (view with GTKWave)
echo.

REM ================================================================================
REM Test 5: Pipeline Visualization
REM ================================================================================

echo [5/5] Compiling Pipeline Visualization...
iverilog -g2012 -Wall -o pipeline_test.exe register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v processor_top.v tb_pipeline_visualization.v
if %errorlevel% neq 0 (
    echo ERROR: Pipeline test compilation failed!
    pause
    exit /b 1
)

echo [5/5] Running Pipeline Visualization...
vvp pipeline_test.exe
if %errorlevel% neq 0 (
    echo ERROR: Pipeline test failed!
    pause
    exit /b 1
)
echo [5/5] Pipeline Visualization: PASSED
echo.
echo Generated: pipeline_viz.vcd (view with GTKWave)
echo.

REM ================================================================================
REM Summary
REM ================================================================================

echo.
echo ========================================
echo    ALL TESTS PASSED SUCCESSFULLY!
echo ========================================
echo.
echo Test Results:
echo   [OK] ALU Test
echo   [OK] Hazard Detection Test
echo   [OK] Full Processor Test
echo   [OK] Control Hazard Test
echo   [OK] Pipeline Visualization
echo.
echo Waveform Files Generated:
echo   - processor_test.vcd
echo   - control_hazards.vcd
echo   - pipeline_viz.vcd
echo.
echo To view waveforms, run:
echo   gtkwave processor_test.vcd
echo.
echo For detailed documentation, see:
echo   - README.md
echo   - QUICK_START.md
echo   - TEST_NASIL_EDILIR.txt
echo.
pause

