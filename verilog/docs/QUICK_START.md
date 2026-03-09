# 🚀 HIZLI BAŞLANGIÇ REHBERİ

## 1. Araçları Kurun (5 dakika)

### Windows
1. [Icarus Verilog İndir](http://bleyer.org/icarus/) ve kur
2. [GTKWave İndir](http://gtkwave.sourceforge.net/) ve kur
3. Git Bash veya PowerShell kullanın

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave make
```

### macOS
```bash
brew install icarus-verilog gtkwave
```

---

## 2. Testleri Çalıştırın (2 dakika)

### Tüm testleri çalıştır:
```bash
cd verilog
make test-all
```

### Sadece ana işlemci testini çalıştır:
```bash
make processor
```

---

## 3. Sonuçları Kontrol Edin

### Başarılı test çıktısı şöyle görünmeli:

```
========================================
   Test Results Summary                
========================================
Total Cycles: 16
Final PC: 9

Register File Contents:
R0 = 0x0000 (should always be 0)
R1 = 0x000A (10) ✓
R2 = 0x0014 (20) ✓
R3 = 0x001E (30) ✓
R4 = 0x000A (10) ✓
R5 = 0x001E (30) ✓
R6 = 0x0028 (40) ✓

Data Memory Contents:
MEM[0] = 0x001E (30) ✓
MEM[1] = 0x000A (10) ✓
MEM[2] = 0x0028 (40) ✓

========================================
   Simulation Complete                 
========================================
```

---

## 4. Waveform'u Görüntüleyin

```bash
make view-processor
```

GTKWave açıldığında şu sinyalleri ekleyin:
- `uut.clk`
- `uut.pc`
- `uut.instruction`
- `uut.regfile.registers[1]` (R1)
- `uut.regfile.registers[2]` (R2)
- `uut.regfile.registers[3]` (R3)

---

## 5. Diğer Testler

```bash
make alu          # ALU testi (çok hızlı)
make hazard       # Hazard detection testi
make control      # Branch/jump testi
make pipeline     # Detaylı pipeline görselleştirmesi
```

---

## 🎯 Test Başarı Kriterleri

### ALU Testi ✓
- Tüm operasyonlar doğru sonuç vermeli
- Zero flag doğru çalışmalı

### Hazard Testi ✓
- Load-use hazard'da stall olmalı
- Forwarding doğru çalışmalı
- R0'a forwarding olmamalı

### İşlemci Testi ✓
- R1 = 10
- R2 = 20
- R3 = 30
- R6 = 40 (load-use hazard'ı aşarak)
- Memory doğru güncellenmiş olmalı

### Control Testi ✓
- Branch'ler doğru adrese zıplamalı
- JAL return adresini R7'ye kaydetmeli
- JR register'dan zıplamalı

---

## 🐛 Sorun mu Yaşıyorsunuz?

### "iverilog: command not found"
→ Icarus Verilog kurulu değil. Yukarıdaki kurulum adımlarını takip edin.

### "make: command not found" (Windows)
→ Git Bash kullanın veya manuel test komutlarını kullanın:
```bash
iverilog -g2012 -Wall -o test.out processor_top.v register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v tb_processor.v
vvp test.out
```

### Test sonuçları yanlış
→ Detaylı görselleştirme çalıştırın:
```bash
make pipeline
```

### GTKWave açılmıyor
→ Manuel olarak açın:
```bash
gtkwave processor_test.vcd
```

---

## 📝 Sonraki Adımlar

1. ✅ Testleri başarıyla çalıştırdınız
2. 📊 Waveform'ları incelediz
3. 📄 Raporunuza ekleyecek screenshot'lar aldınız
4. 🎓 **README.md** dosyasını okuyun (daha detaylı bilgi)
5. 📖 **VERILOG_README.md** dosyasını inceleyin (teknik detaylar)

---

## ⚡ Hızlı Referans

| Komut | Ne Yapar |
|-------|----------|
| `make test-all` | Tüm testleri çalıştır |
| `make processor` | Ana işlemci testini çalıştır |
| `make view-processor` | Waveform'u görüntüle |
| `make check` | Sadece syntax kontrol et |
| `make clean` | Geçici dosyaları temizle |
| `make help` | Tüm komutları listele |

---

**Herhangi bir sorun yaşarsanız README.md ve simulation_guide.txt dosyalarına bakın!**

**Başarılar! 🎉**

