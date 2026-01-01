# Firebase Kurulum Talimatları

## Firebase Projesi Oluşturma

1. **Firebase Console'a gidin**: https://console.firebase.google.com/
2. **Yeni proje oluşturun** veya mevcut bir projeyi seçin
3. **Web uygulaması ekleyin**:
   - Proje ayarlarına gidin
   - "Web uygulaması ekle" butonuna tıklayın
   - Uygulama adını girin (örn: "Dedikodu Web")
   - Firebase Hosting'i etkinleştirmeyin (şimdilik)

## Firebase Yapılandırması

### 1. Web Yapılandırma Bilgilerini Alın

Firebase Console'dan aşağıdaki bilgileri kopyalayın:
- API Key
- App ID
- Messaging Sender ID
- Project ID
- Auth Domain
- Storage Bucket

### 2. firebase_options.dart Dosyasını Güncelleyin

`lib/firebase_options.dart` dosyasındaki placeholder değerleri gerçek değerlerle değiştirin:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIza...', // Firebase Console'dan alın
  appId: '1:123...', // Firebase Console'dan alın
  messagingSenderId: '123...', // Firebase Console'dan alın
  projectId: 'your-project-id', // Firebase Console'dan alın
  authDomain: 'your-project.firebaseapp.com',
  storageBucket: 'your-project.appspot.com',
);
```

### 3. Firestore Database Oluşturun

1. Firebase Console'da **Firestore Database** bölümüne gidin
2. **Create database** butonuna tıklayın
3. **Test mode** seçin (geliştirme için)
4. Lokasyon seçin (örn: europe-west3)

### 4. Authentication Ayarları

1. Firebase Console'da **Authentication** bölümüne gidin
2. **Get started** butonuna tıklayın
3. **Sign-in method** sekmesine gidin
4. **Anonymous** seçeneğini etkinleştirin

### 5. Firestore Security Rules

Firestore Database > Rules sekmesinde aşağıdaki kuralları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Confessions collection
    match /confessions/{confessionId} {
      allow read: if resource.data.status == 'approved';
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                     (request.auth.uid == resource.data.authorId || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isModerator == true);
      allow delete: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isModerator == true;
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth != null && 
                       (request.auth.uid == resource.data.authorId || 
                        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isModerator == true);
      }
    }
  }
}
```

## Firestore İndeksleri

Aşağıdaki composite index'leri oluşturun (Firestore Console > Indexes):

1. **confessions** koleksiyonu:
   - Fields: `status` (Ascending), `createdAt` (Descending)
   
2. **confessions** koleksiyonu (şehir filtresi için):
   - Fields: `cityPlateCode` (Ascending), `status` (Ascending), `createdAt` (Descending)
   
3. **confessions** koleksiyonu (ilçe filtresi için):
   - Fields: `districtId` (Ascending), `status` (Ascending), `createdAt` (Descending)

## Test

Uygulamayı çalıştırın:
```bash
flutter run -d chrome
```

Firebase bağlantısı başarılı olursa, console'da "Firebase initialized successfully" mesajını göreceksiniz.

## Sorun Giderme

### Firebase initialization error
- `firebase_options.dart` dosyasındaki değerlerin doğru olduğundan emin olun
- Firebase Console'da web uygulamasının eklendiğini kontrol edin

### Firestore permission denied
- Security rules'un doğru yapılandırıldığından emin olun
- Anonymous authentication'ın etkin olduğunu kontrol edin
