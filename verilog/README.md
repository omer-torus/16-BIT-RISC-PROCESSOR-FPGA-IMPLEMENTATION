# 16-bit RISC İşlemci - Verilog İmplementasyonu
## Phase 3: Verilog Kodu ve Test Ortamı

---

## 📋 Klasör İçeriği

Bu klasör, 16-bit RISC işlemcinizin tam Verilog implementasyonunu içerir.

### 📁 Dosya Yapısı

```
verilog/
├── README.md                          # Bu dosya
├── Makefile                           # Otomatik test sistemi
├── VERILOG_README.md                  # Detaylı teknik dokümantasyon
├── simulation_guide.txt               # Simülasyon rehberi
│
├── Core Modules (İşlemci Birimleri):
│   ├── processor_top.v                # Ana işlemci modülü
│   ├── register_file.v                # Register dosyası
│   ├── alu.v                          # ALU
│   ├── control_unit.v                 # Kontrol birimi
│   ├── hazard_detection_unit.v        # Hazard algılama
│   ├── forwarding_unit.v              # Data forwarding
│   ├── pipeline_registers.v           # Pipeline register'ları
│   ├── instruction_memory.v           # Instruction memory
│   └── data_memory.v                  # Data memory
│
└── Test Benches (Test Dosyaları):
    ├── tb_processor.v                 # Ana işlemci testi
    ├── tb_alu.v                       # ALU testi
    ├── tb_hazard_forwarding.v         # Hazard testi
    ├── tb_control_hazards.v           # Branch/jump testi
    └── tb_pipeline_visualization.v    # Pipeline görselleştirme
```

---

## 🚀 HIZLI BAŞLANGIÇ

### 1. Gerekli Araçları Kurun

**Windows:**
```bash
# Icarus Verilog: http://bleyer.org/icarus/
# GTKWave: http://gtkwave.sourceforge.net/
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave make
```

**macOS:**
```bash
brew install icarus-verilog gtkwave
```

### 2. Test Edin

```bash
cd verilog
make test-all
```

---

## 📝 TEST KOMUTLARI

### Tüm Testleri Çalıştır
```bash
make test-all
```

### Tek Tek Testler
```bash
make processor    # Ana işlemci testi (en kapsamlı)
make alu          # ALU birim testi
make hazard       # Hazard detection testi
make control      # Branch/jump testi
make pipeline     # Pipeline görselleştirme
```

### Waveform Görüntüle
```bash
make view-processor    # Ana test waveform'u
make view-control      # Branch test waveform'u
make view-pipeline     # Pipeline debug waveform'u
```

### Syntax Kontrolü
```bash
make check
```

### Temizlik
```bash
make clean
```

---

## ✅ BEKLENEN TEST SONUÇLARI

### 1. ALU Testi (`make alu`)
```
========================================
   ALU Module Test Bench               
========================================

ADD: 100 + 50 = 150 (Expected: 150)
SUB: 100 - 50 = 50 (Expected: 50)
SUB: 100 - 100 = 0, Zero=1 (Expected: 0, Zero=1)
AND: 0xFF00 & 0x0F0F = 0x0F00 (Expected: 0x0F00)
OR:  0xFF00 | 0x0F0F = 0xFF0F (Expected: 0xFF0F)
SLT: 10 < 20 = 1 (Expected: 1)
SLT: 30 < 20 = 0 (Expected: 0)
SLL: 0x0001 << 3 = 0x0008 (Expected: 0x0008)
SRL: 0x0080 >> 4 = 0x0008 (Expected: 0x0008)

========================================
   ALU Test Complete                   
========================================
```

### 2. Hazard Testi (`make hazard`)
```
========================================
   Hazard & Forwarding Test Bench      
========================================

Test 1: Load-Use Hazard Detection
Scenario: LW R1, 0(R0) followed by ADD R2, R1, R3
Result: Stall=1, PC_Write=0, IF_ID_Write=0
Expected: Stall=1, PC_Write=0, IF_ID_Write=0

Test 2: No Hazard
Result: Stall=0, PC_Write=1, IF_ID_Write=1
Expected: Stall=0, PC_Write=1, IF_ID_Write=1

Test 3: EX/MEM Stage Forwarding
Result: Forward_A=10, Forward_B=00
Expected: Forward_A=10 (from EX/MEM), Forward_B=00
```

### 3. İşlemci Testi (`make processor`)
```
========================================
   Test Results Summary                
========================================
Total Cycles: 16
Final PC: 9

Register File Contents:
R0 = 0x0000 (should always be 0)
R1 = 0x000A (10)
R2 = 0x0014 (20)
R3 = 0x001E (30)
R4 = 0x000A (10)
R5 = 0x001E (30)
R6 = 0x0028 (40)
R7 = 0x0000

Data Memory Contents:
MEM[0] = 0x001E (30)
MEM[1] = 0x000A (10)
MEM[2] = 0x0028 (40)
```

### 4. Control Hazard Testi (`make control`)
```
Register Contents:
R1 = 6
R2 = 25
R3 = 101
R7 = 10 (return address for JAL)
```

---

## 🔍 MANUEL TEST (Adım Adım)

Eğer Makefile kullanmak istemezseniz:

### 1. Syntax Kontrolü
```bash
iverilog -g2012 -t null processor_top.v register_file.v alu.v control_unit.v \
         hazard_detection_unit.v forwarding_unit.v pipeline_registers.v \
         instruction_memory.v data_memory.v
```

### 2. ALU Testini Derle
```bash
iverilog -g2012 -Wall -o alu_test.out alu.v tb_alu.v
```

### 3. Testi Çalıştır
```bash
vvp alu_test.out
```

### 4. Tam İşlemci Testini Derle
```bash
iverilog -g2012 -Wall -o processor_test.out \
    register_file.v alu.v control_unit.v \
    hazard_detection_unit.v forwarding_unit.v \
    pipeline_registers.v instruction_memory.v \
    data_memory.v processor_top.v tb_processor.v
```

### 5. İşlemci Testini Çalıştır
```bash
vvp processor_test.out
```

### 6. Waveform'u Görüntüle
```bash
gtkwave processor_test.vcd
```

---

## 📊 WAVEFORM ANALİZİ

GTKWave'de görmeniz gereken önemli sinyaller:

### Temel Sinyaller
- `uut.clk` - Clock sinyali
- `uut.pc` - Program Counter
- `uut.instruction` - Mevcut instruction
- `uut.cycle_count` - Cycle sayacı

### Pipeline Durumu
- `uut.if_id_valid` - IF/ID stage geçerli mi?
- `uut.id_ex_valid` - ID/EX stage geçerli mi?
- `uut.ex_mem_valid` - EX/MEM stage geçerli mi?
- `uut.mem_wb_valid` - MEM/WB stage geçerli mi?

### Hazard Sinyalleri
- `uut.stall` - Pipeline stall (load-use hazard)
- `uut.flush` - Pipeline flush (branch/jump)
- `uut.forward_a` - Forwarding kontrol A
- `uut.forward_b` - Forwarding kontrol B

### Register'lar
- `uut.regfile.registers[0]` - R0 (her zaman 0)
- `uut.regfile.registers[1]` - R1
- `uut.regfile.registers[2]` - R2
- ... (R7'ye kadar)

---

## 🐛 SORUN GİDERME

### Problem: "command not found: iverilog"
**Çözüm:** Icarus Verilog kurulu değil. Yukarıdaki kurulum adımlarını takip edin.

### Problem: "syntax error"
**Çözüm:** 
```bash
make check  # Syntax hatalarını kontrol et
```

### Problem: Test sonuçları beklenen değerleri göstermiyor
**Çözüm:**
```bash
make pipeline  # Detaylı pipeline görselleştirmesini çalıştır
```

### Problem: Waveform açılmıyor
**Çözüm:** GTKWave kurulu mu kontrol edin:
```bash
gtkwave --version
```

---

## 📈 PERFORMANS METRİKLERİ

### CPI (Cycles Per Instruction)

**İdeal durum:**
- CPI = 1.0 (her cycle'da bir instruction tamamlanır)

**Hazard'larla:**
- Load-use hazard: +1 cycle stall
- Branch taken: +2 cycle flush

**Örnek hesaplama:**
```
Test program: 9 instruction
Total cycles: 16
CPI = 16 / 9 = 1.78

Breakdown:
- Pipeline fill: 4 cycles
- Normal execution: 9 cycles
- Hazards: 3 cycles (1 load-use stall)
```

---

## 🎯 FPGA SENTEZİ (İsteğe Bağlı)

Bu Verilog kodu FPGA'de sentezlenebilir.

### Xilinx Vivado için:
```tcl
create_project risc_processor ./project -part xc7a35tcpg236-1
add_files {processor_top.v register_file.v alu.v control_unit.v \
           hazard_detection_unit.v forwarding_unit.v pipeline_registers.v \
           instruction_memory.v data_memory.v}
set_property top processor_top [current_fileset]
launch_runs synth_1
wait_on_run synth_1
```

### Beklenen Kaynak Kullanımı:
- **LUTs:** ~1500
- **Flip-Flops:** ~500
- **BRAM:** 2 blok
- **Max Frequency:** ~50-100 MHz

---

## 📚 EK KAYNAKLAR

- **VERILOG_README.md** - Detaylı teknik dokümantasyon
- **simulation_guide.txt** - Kapsamlı simülasyon rehberi
- **Icarus Verilog:** http://iverilog.icarus.com/
- **GTKWave:** http://gtkwave.sourceforge.net/

---

## ✅ Phase 3 Teslim Checklist

- [x] Tüm processor unit'lerin Verilog implementasyonu
- [x] 5-stage pipeline yapısı
- [x] Hazard detection unit
- [x] Forwarding unit
- [x] Test bench'ler
- [x] Simulation sonuçları
- [x] Timing analizi
- [x] Dokümantasyon

---

## 🎓 RAPOR İÇİN ÖNERİLER

Raporunuza ekleyebilecekleriniz:

1. **Test sonuçları screenshot'ları**
   - Terminal output
   - Waveform görüntüleri

2. **Performance metrics**
   - CPI hesaplamaları
   - Hazard frequency analizi

3. **Pipeline diagrams**
   - Pipeline visualization output'u

4. **Code statistics**
   - Toplam satır sayısı
   - Modül sayısı
   - Test coverage

---

**Teslim Tarihi:** 20 Ocak 2025, 23:59  
**İyi Çalışmalar! 🚀**

