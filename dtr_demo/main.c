#include <stdint.h>

// README dosyasında belirttiğiniz UART1 Base Adresi
#define UART1_BASE_ADDR 0x10000000

// UART Register tanımlamaları (Kendi UART modülünüzün offsetlerine göre ayarlayın)
// Varsayılan olarak TX, RX ve Status registerlarını basitçe modelliyoruz.
volatile uint32_t *const UART1_TX     = (uint32_t *)(UART1_BASE_ADDR + 0x00);
volatile uint32_t *const UART1_RX     = (uint32_t *)(UART1_BASE_ADDR + 0x04);
volatile uint32_t *const UART1_STATUS = (uint32_t *)(UART1_BASE_ADDR + 0x08);

// Tek bir karakter gönderme fonksiyonu
void uart_send_char(char c) {
    // TX buffer'ın boşalmasını bekle (kendi status mantığınıza göre uyarlayın)
    // while((*UART1_STATUS & 0x01) == 0); 
    *UART1_TX = c;
}

// String gönderme fonksiyonu
void uart_send_string(const char *str) {
    while (*str) {
        uart_send_char(*str++);
    }
}

// Karakter okuma fonksiyonu (Polling)
char uart_receive_char() {
    // RX buffer'a veri gelene kadar bekle
    // while((*UART1_STATUS & 0x02) == 0);
    return (char)(*UART1_RX);
}

int main() {
    // 1. Adım: Jüriye hazır olduğumuzu bildiren 'R' karakterini gönder
    uart_send_char('R');

    // 2. Adım: Jürinin test ortamından 'A' (Acknowledge) onayı gelene kadar bekle
    char rx_data = 0;
    while (rx_data != 'A') {
        rx_data = uart_receive_char();
    }

    // 3. Adım: 'A' harfi geldiyse asıl parolayı gönder ve testi bitir!
    uart_send_string("Hello World!");

    // İşlemciyi güvenli bir şekilde sonsuz döngüde tut
    while(1) {
        __asm__ volatile("nop");
    }

    return 0;
}