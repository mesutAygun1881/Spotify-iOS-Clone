# Spotify iOS SDK Manuel Entegrasyon Adımları

Bu doküman, Spotify iOS SDK'nın projeye manuel olarak nasıl entegre edileceğini ve "libarclite" hatasının nasıl çözüleceğini detaylı olarak açıklar.

## 1. Gerekli Doğru SDK Sürümünü İndirme

1. [Spotify Developer Dashboard](https://developer.spotify.com/documentation/ios/) adresine gidin
2. iOS SDK'nın en son sürümünü indirin (sürüm 1.0.3 veya daha yeni)
3. İndirilen ZIP dosyasını açın

## 2. Proje Ayarlarını Güncelleme

### Minimum Deployment Target'ı Yükseltme

`libarclite_iphoneos.a` hatası, projenin minimum iOS deployment target'ı ile ilgilidir. Yeni Xcode sürümleri bu kitaplığı içermediğinden, minimum deployment target'ı yükseltmemiz gerekiyor.

1. Podfile'ı aşağıdaki şekilde güncelleyin:
```ruby
platform :ios, '15.0'
```

2. Xcode projesinde:
   - Projenizi seçin
   - "General" sekmesine gidin
   - "Deployment Info" bölümünde "iOS 15.0" veya daha yüksek bir değer seçin
   
3. Terminal'de pod install komutunu çalıştırın:
```bash
pod install
```

## 3. Spotify SDK'yı Projeye Ekleme

1. İndirdiğiniz ve açtığınız SDK klasöründen `SpotifyiOS.framework` dosyasını bulun
2. Bu framework dosyasını Xcode projenize sürükleyip bırakın
3. "Copy items if needed" (Gerekirse öğeleri kopyala) seçeneğini işaretleyin
4. "Add to targets" (Hedeflere ekle) bölümünde projenizi seçin
5. "Finish" (Bitir) düğmesine tıklayın

## 4. Framework Ayarlarını Yapılandırma

1. Xcode'da projenizi seçin
2. "Build Phases" sekmesine gidin 
3. "+ New" düğmesine tıklayın ve "New Copy Files Phase" seçin
4. Açılan bölümde:
   - Destination: "Frameworks" olarak ayarlayın
   - "+" düğmesine tıklayın ve `SpotifyiOS.framework` dosyasını ekleyin
   - "Copy only when installing" seçeneğini işaretleyin

5. "Build Settings" sekmesine gidin
6. "Framework Search Paths" ayarında SpotifyiOS.framework dosyasının bulunduğu dizini ekleyin
7. "Other Linker Flags" ayarına `-ObjC` ekleyin

## 5. info.plist Ayarlarını Yapma

Info.plist dosyanızın aşağıdaki değerleri içerdiğinden emin olun:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
    <string>spotify-sdk</string>
</array>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.spotify.ios-sdk-auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>spotify-sdk-c658cfb036f34f6e835e59410b8e0ffb</string>
        </array>
    </dict>
</array>
```

## 6. Kod İçine Import Ekleme

SDK'yı kullanacağınız her dosyada import'u ekleyin:

```swift
import SpotifyiOS
```

## 7. Hata Giderme - "libarclite" Sorunu

Bu hata genellikle eski SDK'ların yeni Xcode sürümleri ile çalıştırılmasından kaynaklanır. Çözüm adımları:

1. Build Settings'de "Build Options" bölümüne gidin
2. "Enable Bitcode" ayarını "No" olarak değiştirin
3. Deployment target'ı iOS 15.0 veya daha yüksek bir değere ayarlayın
4. Temiz bir derleme yapmak için:
   - Xcode'u kapatın
   - Projenizin bulunduğu klasörde bulunan `Pods` klasörünü ve `*.xcworkspace` dosyalarını silin
   - Terminalde aşağıdaki komutları çalıştırın:
   ```bash
   pod deintegrate
   pod setup
   pod install
   ```
   - Xcode'u yeniden açın ve `.xcworkspace` dosyasını açın

5. Hala sorun yaşıyorsanız, SDK'yı bir "Embedded Binary" olarak eklemeyi deneyin:
   - Project Navigator'da projenizi seçin
   - "General" sekmesine gidin
   - "Frameworks, Libraries, and Embedded Content" bölümüne SpotifyiOS.framework'ü ekleyin
   - "Embed" seçeneğini "Embed & Sign" olarak ayarlayın

## 8. Projeyi Derleme ve Test Etme

1. Xcode'da projenizi derleyin
2. Spotify uygulamasının cihazınızda yüklü olduğundan emin olun
3. Uygulamanızı çalıştırın ve Spotify bağlantısını test edin

## Troubleshooting

1. "Framework not found SpotifyiOS" hatası:
   - Framework dosyasının doğru konumda olduğunu kontrol edin
   - Framework Search Paths ayarlarını kontrol edin

2. "Symbol not found" hataları:
   - Other Linker Flags ayarına `-ObjC` eklediğinizden emin olun
   
3. Derleme sırasında "libarclite" hatası:
   - Minimum deployment target'ın iOS 15.0 veya daha yüksek olduğundan emin olun
   - Enable Bitcode ayarını No olarak değiştirin 