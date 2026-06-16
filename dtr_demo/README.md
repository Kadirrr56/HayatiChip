# HayatiChip SoC - DTR Teknotest Entegrasyonu

Bu dizin, TEKNOFEST 2026 Çip Tasarım Yarışması Mikrodenetleyici Tasarım Kategorisi DTR aşaması değerlendirmeleri için hazırlanan "teknotest" ortamı entegrasyonunu içermektedir.

## Proje ve Donanım Uyumluluğu
* **Proje Adı:** HayatiChip SoC
* **Geliştirici Ekip:** Abdulkadir Oluç, Furkan, Hasan, Tuncay, Kaya Pulat (Muğla Sıtkı Koçman Üniversitesi)
* **Hedeflenen Araç Sürümü:** AMD Xilinx Vivado 2021.2
* **Hedef FPGA Mimarisi:** Artix-7 (xc7a35tcpg236-1)

## Sistem ve Bağlantı Mimarisi (Top-Level)
Jüri tarafından sağlanan `teknotest` testbench ortamı ile HayatiChip arasındaki fiziksel ve mantıksal bağlantı şu şekilde kurulmuştur:
* Testbench ortamından gelen `clk` ve `rst_n` sinyalleri sistemin ana saat ve reset omurgasına bağlanmıştır.
* Testbench'teki `uart_rx` ve `uart_tx` sinyalleri, sistemimizdeki **UART1 (0x1000_0000)** modülüne yönlendirilmiştir. 
* Sisteme entegre edilen Yapay Zekâ Hızlandırıcısı (TFLite), I2C, QSPI ve özel veri akışı sağlayan UART2 modülleri, bu temel çekirdek/UART testinde asenkron olarak arka planda izole tutulmuş; testin kararlılığı güvence altına alınmıştır.

## Simülasyon Çalıştırma Adımları
1. AMD Xilinx Vivado 2021.2 aracı üzerinden `HayatiChip_Teknotest.xpr` proje dosyasını açın.
2. Flow Navigator paneli üzerinden **"Run Simulation -> Run Behavioral Simulation"** adımlarını izleyin.
3. Testbench loglarının Tcl Console üzerinde hatasız aktığını ve UART el sıkışmalarının tamamlandığını gözlemleyebilirsiniz.
