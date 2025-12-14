#include <M5Unified.h>
#include <aquestalk.h>
#include "AquesTalkTTS.h"

void setup(void)
{
  auto cfg = M5.config();
  M5.begin(cfg);
  
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("========== Atomic Echo Base 音声合成 ==========");
  
  // RecordPlay.inoと同じピン設定
  auto spk_cfg = M5.Speaker.config();
  spk_cfg.pin_data_out = 5;   // I2S DOUT
  spk_cfg.pin_bck = 8;        // I2S BCK
  spk_cfg.pin_ws = 6;         // I2S WS (LRCLK)
  spk_cfg.sample_rate = 24000; // AquesTalk推奨
  spk_cfg.stereo = false;
  spk_cfg.buzzer = false;
  spk_cfg.magnification = 16;
  
  M5.Speaker.config(spk_cfg);
  M5.Speaker.begin();
  M5.Speaker.setVolume(255);
  
  Serial.println("スピーカー初期化完了");
  
  // AquesTalkの初期化
  if (TTS.create()) {
    Serial.println("ERR:TTS.create()");
    return;
  }
  
  Serial.println("AquesTalk初期化完了");
  
  // 音声合成テスト
  Serial.println("音声1");
  TTS.play("konnichiwa");
  TTS.wait();
  
  delay(500);
  
  Serial.println("音声2");
  TTS.play("kawakawa"); 
  TTS.wait();
  
  Serial.println("テスト完了");
}

void loop(void)
{
  delay(5000);
  Serial.println("ループ内音声");
  TTS.play("dosachudesu");
  TTS.wait();
}
